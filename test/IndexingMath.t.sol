// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Test, stdError } from "../lib/forge-std/src/Test.sol";

import { IndexingMath } from "../src/libs/IndexingMath.sol";
import { UIntMath } from "../src/libs/UIntMath.sol";

/// @title  Wrapper exposing `IndexingMath`'s internal functions as external calls.
/// @author M^0 Labs
/// @dev    Reverts raised by an inlined internal library call cannot be captured by `vm.expectRevert`,
///         so every assertion below goes through this wrapper.
contract IndexingMathWrapper {
    function getPresentAmountRoundedDown(uint112 principal, uint128 index) external pure returns (uint256) {
        return IndexingMath.getPresentAmountRoundedDown(principal, index);
    }

    function getPresentAmountRoundedUp(uint112 principal, uint128 index) external pure returns (uint256) {
        return IndexingMath.getPresentAmountRoundedUp(principal, index);
    }

    function getPrincipalAmountRoundedDown(uint256 presentAmount, uint128 index) external pure returns (uint112) {
        return IndexingMath.getPrincipalAmountRoundedDown(presentAmount, index);
    }

    function getPrincipalAmountRoundedUp(uint256 presentAmount, uint128 index) external pure returns (uint112) {
        return IndexingMath.getPrincipalAmountRoundedUp(presentAmount, index);
    }

    function getSafePrincipalAmountRoundedUp(
        uint256 presentAmount,
        uint128 index,
        uint112 maxPrincipalAmount
    ) external pure returns (uint112) {
        return IndexingMath.getSafePrincipalAmountRoundedUp(presentAmount, index, maxPrincipalAmount);
    }
}

contract IndexingMathTests is Test {
    uint56 internal constant _EXP_SCALED_ONE = IndexingMath.EXP_SCALED_ONE;

    /// @dev The largest present amount for which `presentAmount * EXP_SCALED_ONE` still fits a uint256.
    uint256 internal constant _MAX_SCALABLE = type(uint256).max / _EXP_SCALED_ONE;

    /// @dev What is left of a uint256 after `_MAX_SCALABLE * EXP_SCALED_ONE`, i.e. the room the `+ index - 1`
    ///      term of `getPrincipalAmountRoundedUp` has before it overflows.
    uint256 internal constant _ROUNDING_HEADROOM = type(uint256).max - (_MAX_SCALABLE * _EXP_SCALED_ONE);

    IndexingMathWrapper public indexingMath;

    function setUp() external {
        indexingMath = new IndexingMathWrapper();
    }

    /* ============ EXP_SCALED_ONE ============ */

    function test_expScaledOne() external pure {
        assertEq(_EXP_SCALED_ONE, 1e12);
    }

    /* ============ getPresentAmountRoundedDown ============ */

    function test_getPresentAmountRoundedDown() external view {
        assertEq(indexingMath.getPresentAmountRoundedDown(0, _EXP_SCALED_ONE), 0);
        assertEq(indexingMath.getPresentAmountRoundedDown(0, 0), 0);

        // An index of one is the identity.
        assertEq(indexingMath.getPresentAmountRoundedDown(1, _EXP_SCALED_ONE), 1);
        assertEq(indexingMath.getPresentAmountRoundedDown(1_000, _EXP_SCALED_ONE), 1_000);
        assertEq(indexingMath.getPresentAmountRoundedDown(type(uint112).max, _EXP_SCALED_ONE), type(uint112).max);

        assertEq(indexingMath.getPresentAmountRoundedDown(1, 2 * uint128(_EXP_SCALED_ONE)), 2);
        assertEq(indexingMath.getPresentAmountRoundedDown(10, _EXP_SCALED_ONE / 2), 5);

        // Truncating cases: the exact product is not a multiple of `EXP_SCALED_ONE`.
        assertEq(indexingMath.getPresentAmountRoundedDown(1, _EXP_SCALED_ONE - 1), 0); // Different than rounded up
        assertEq(indexingMath.getPresentAmountRoundedDown(1, _EXP_SCALED_ONE + 1), 1); // Different than rounded up
        assertEq(indexingMath.getPresentAmountRoundedDown(3, _EXP_SCALED_ONE + 1), 3); // Different than rounded up
        assertEq(indexingMath.getPresentAmountRoundedDown(3, (_EXP_SCALED_ONE / 2) + 1), 1); // Different than up
    }

    /* ============ getPresentAmountRoundedUp ============ */

    function test_getPresentAmountRoundedUp() external view {
        assertEq(indexingMath.getPresentAmountRoundedUp(0, _EXP_SCALED_ONE), 0);
        assertEq(indexingMath.getPresentAmountRoundedUp(0, 0), 0);

        // An index of one is the identity.
        assertEq(indexingMath.getPresentAmountRoundedUp(1, _EXP_SCALED_ONE), 1);
        assertEq(indexingMath.getPresentAmountRoundedUp(1_000, _EXP_SCALED_ONE), 1_000);
        assertEq(indexingMath.getPresentAmountRoundedUp(type(uint112).max, _EXP_SCALED_ONE), type(uint112).max);

        assertEq(indexingMath.getPresentAmountRoundedUp(1, 2 * uint128(_EXP_SCALED_ONE)), 2);
        assertEq(indexingMath.getPresentAmountRoundedUp(10, _EXP_SCALED_ONE / 2), 5);

        // Ceiling cases: exactly one unit above the rounded down result.
        assertEq(indexingMath.getPresentAmountRoundedUp(1, _EXP_SCALED_ONE - 1), 1); // Different than rounded down
        assertEq(indexingMath.getPresentAmountRoundedUp(1, _EXP_SCALED_ONE + 1), 2); // Different than rounded down
        assertEq(indexingMath.getPresentAmountRoundedUp(3, _EXP_SCALED_ONE + 1), 4); // Different than rounded down
        assertEq(indexingMath.getPresentAmountRoundedUp(3, (_EXP_SCALED_ONE / 2) + 1), 2); // Different than down
    }

    /* ============ getPrincipalAmountRoundedDown ============ */

    function test_getPrincipalAmountRoundedDown() external view {
        assertEq(indexingMath.getPrincipalAmountRoundedDown(0, _EXP_SCALED_ONE), 0);
        assertEq(indexingMath.getPrincipalAmountRoundedDown(0, type(uint128).max), 0);

        // An index of one is the identity.
        assertEq(indexingMath.getPrincipalAmountRoundedDown(1, _EXP_SCALED_ONE), 1);
        assertEq(indexingMath.getPrincipalAmountRoundedDown(1_000, _EXP_SCALED_ONE), 1_000);
        assertEq(indexingMath.getPrincipalAmountRoundedDown(type(uint112).max, _EXP_SCALED_ONE), type(uint112).max);

        assertEq(indexingMath.getPrincipalAmountRoundedDown(2, 2 * uint128(_EXP_SCALED_ONE)), 1);
        assertEq(indexingMath.getPrincipalAmountRoundedDown(5, _EXP_SCALED_ONE / 2), 10);

        // Truncating cases: the exact quotient is not an integer.
        assertEq(indexingMath.getPrincipalAmountRoundedDown(1, _EXP_SCALED_ONE + 1), 0); // Different than rounded up
        assertEq(indexingMath.getPrincipalAmountRoundedDown(1, _EXP_SCALED_ONE - 1), 1); // Different than rounded up
        assertEq(indexingMath.getPrincipalAmountRoundedDown(3, 2 * uint128(_EXP_SCALED_ONE)), 1); // Different than up
    }

    function test_getPrincipalAmountRoundedDown_divisionByZero() external {
        vm.expectRevert(IndexingMath.DivisionByZero.selector);
        indexingMath.getPrincipalAmountRoundedDown(1, 0);

        // The zero index is rejected even when the present amount is zero.
        vm.expectRevert(IndexingMath.DivisionByZero.selector);
        indexingMath.getPrincipalAmountRoundedDown(0, 0);
    }

    /// @dev The result is cast through `UIntMath.safe112`, which reverts rather than truncating.
    function test_getPrincipalAmountRoundedDown_invalidUInt112() external {
        uint256 justOverUInt112 = uint256(type(uint112).max) + 1;

        assertEq(indexingMath.getPrincipalAmountRoundedDown(justOverUInt112 - 1, _EXP_SCALED_ONE), type(uint112).max);

        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        indexingMath.getPrincipalAmountRoundedDown(justOverUInt112, _EXP_SCALED_ONE);
    }

    /// @dev The present amount is widened to uint256, so `presentAmount * EXP_SCALED_ONE` is bounded by the scaling
    ///      limit `type(uint256).max / EXP_SCALED_ONE`. Above it, checked math panics instead of wrapping.
    function test_getPrincipalAmountRoundedDown_scalingLimit() external {
        // At the limit the multiplication is fine and only the uint112 cap rejects the result.
        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        indexingMath.getPrincipalAmountRoundedDown(_MAX_SCALABLE, _EXP_SCALED_ONE);

        vm.expectRevert(stdError.arithmeticError);
        indexingMath.getPrincipalAmountRoundedDown(_MAX_SCALABLE + 1, _EXP_SCALED_ONE);

        vm.expectRevert(stdError.arithmeticError);
        indexingMath.getPrincipalAmountRoundedDown(type(uint256).max, type(uint128).max);
    }

    /* ============ getPrincipalAmountRoundedUp ============ */

    function test_getPrincipalAmountRoundedUp() external view {
        assertEq(indexingMath.getPrincipalAmountRoundedUp(0, _EXP_SCALED_ONE), 0);
        assertEq(indexingMath.getPrincipalAmountRoundedUp(0, type(uint128).max), 0);

        // An index of one is the identity.
        assertEq(indexingMath.getPrincipalAmountRoundedUp(1, _EXP_SCALED_ONE), 1);
        assertEq(indexingMath.getPrincipalAmountRoundedUp(1_000, _EXP_SCALED_ONE), 1_000);
        assertEq(indexingMath.getPrincipalAmountRoundedUp(type(uint112).max, _EXP_SCALED_ONE), type(uint112).max);

        assertEq(indexingMath.getPrincipalAmountRoundedUp(2, 2 * uint128(_EXP_SCALED_ONE)), 1);
        assertEq(indexingMath.getPrincipalAmountRoundedUp(5, _EXP_SCALED_ONE / 2), 10);

        // Ceiling cases: exactly one unit above the rounded down result.
        assertEq(indexingMath.getPrincipalAmountRoundedUp(1, _EXP_SCALED_ONE + 1), 1); // Different than rounded down
        assertEq(indexingMath.getPrincipalAmountRoundedUp(1, _EXP_SCALED_ONE - 1), 2); // Different than rounded down
        assertEq(indexingMath.getPrincipalAmountRoundedUp(3, 2 * uint128(_EXP_SCALED_ONE)), 2); // Different than down
    }

    function test_getPrincipalAmountRoundedUp_divisionByZero() external {
        vm.expectRevert(IndexingMath.DivisionByZero.selector);
        indexingMath.getPrincipalAmountRoundedUp(1, 0);

        // The zero index is rejected even when the present amount is zero.
        vm.expectRevert(IndexingMath.DivisionByZero.selector);
        indexingMath.getPrincipalAmountRoundedUp(0, 0);
    }

    /// @dev The result is cast through `UIntMath.safe112`, which reverts rather than truncating.
    function test_getPrincipalAmountRoundedUp_invalidUInt112() external {
        uint256 justOverUInt112 = uint256(type(uint112).max) + 1;

        assertEq(indexingMath.getPrincipalAmountRoundedUp(justOverUInt112 - 1, _EXP_SCALED_ONE), type(uint112).max);

        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        indexingMath.getPrincipalAmountRoundedUp(justOverUInt112, _EXP_SCALED_ONE);
    }

    /// @dev Same scaling limit as the rounded down variant, except that the `+ index - 1` ceiling term consumes the
    ///      leftover room of the scaled present amount, so any `index > _ROUNDING_HEADROOM` already panics there.
    function test_getPrincipalAmountRoundedUp_scalingLimit() external {
        // At the limit, with an index small enough for the ceiling term to fit, only the uint112 cap rejects.
        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        indexingMath.getPrincipalAmountRoundedUp(_MAX_SCALABLE, uint128(_ROUNDING_HEADROOM));

        // One unit of index further, the ceiling term itself overflows: `+ index` is applied before `- 1`.
        vm.expectRevert(stdError.arithmeticError);
        indexingMath.getPrincipalAmountRoundedUp(_MAX_SCALABLE, uint128(_ROUNDING_HEADROOM + 1));

        vm.expectRevert(stdError.arithmeticError);
        indexingMath.getPrincipalAmountRoundedUp(_MAX_SCALABLE, type(uint128).max);

        vm.expectRevert(stdError.arithmeticError);
        indexingMath.getPrincipalAmountRoundedUp(_MAX_SCALABLE + 1, _EXP_SCALED_ONE);
    }

    /* ============ getSafePrincipalAmountRoundedUp ============ */

    function test_getSafePrincipalAmountRoundedUp() external view {
        assertEq(indexingMath.getSafePrincipalAmountRoundedUp(0, _EXP_SCALED_ONE, type(uint112).max), 0);

        // Below the cap, it is `getPrincipalAmountRoundedUp`, ceiling included.
        assertEq(indexingMath.getSafePrincipalAmountRoundedUp(1_000, _EXP_SCALED_ONE, 5_000), 1_000);
        assertEq(indexingMath.getSafePrincipalAmountRoundedUp(1, _EXP_SCALED_ONE - 1, 5_000), 2);

        // At the cap it is the cap.
        assertEq(indexingMath.getSafePrincipalAmountRoundedUp(1_000, _EXP_SCALED_ONE, 1_000), 1_000);

        // Above the cap it is the cap.
        assertEq(indexingMath.getSafePrincipalAmountRoundedUp(1_000, _EXP_SCALED_ONE, 500), 500);
        assertEq(indexingMath.getSafePrincipalAmountRoundedUp(1_000, _EXP_SCALED_ONE, 0), 0);
    }

    /// @dev The cap only applies within the uint112 window, up to and including `type(uint112).max` itself.
    function test_getSafePrincipalAmountRoundedUp_capsUpToMaxUInt112() external view {
        uint256 presentAmount = uint256(type(uint112).max);

        assertEq(
            indexingMath.getSafePrincipalAmountRoundedUp(presentAmount, _EXP_SCALED_ONE, type(uint112).max),
            type(uint112).max
        );

        assertEq(indexingMath.getSafePrincipalAmountRoundedUp(presentAmount, _EXP_SCALED_ONE, 1), 1);
    }

    /// @dev Despite its name, this function does not absorb an out of uint112 principal amount: the cap is applied
    ///      after `UIntMath.safe112`, so an uncapped principal amount above `type(uint112).max` still reverts.
    function test_getSafePrincipalAmountRoundedUp_revertsAboveMaxUInt112DespiteCap() external {
        uint256 presentAmount = uint256(type(uint112).max) + 1;

        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        indexingMath.getSafePrincipalAmountRoundedUp(presentAmount, _EXP_SCALED_ONE, 1);

        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        indexingMath.getSafePrincipalAmountRoundedUp(presentAmount, _EXP_SCALED_ONE, type(uint112).max);
    }

    function test_getSafePrincipalAmountRoundedUp_divisionByZero() external {
        vm.expectRevert(IndexingMath.DivisionByZero.selector);
        indexingMath.getSafePrincipalAmountRoundedUp(1, 0, type(uint112).max);
    }

    function test_getSafePrincipalAmountRoundedUp_scalingLimit() external {
        vm.expectRevert(stdError.arithmeticError);
        indexingMath.getSafePrincipalAmountRoundedUp(_MAX_SCALABLE + 1, _EXP_SCALED_ONE, type(uint112).max);
    }

    /* ============ Fuzz ============ */

    /// @dev Neither present amount function can revert for any input of its declared widths.
    function testFuzz_getPresentAmount_neverReverts(uint112 principal, uint128 index) external view {
        indexingMath.getPresentAmountRoundedDown(principal, index);
        indexingMath.getPresentAmountRoundedUp(principal, index);
    }

    /// @dev An index of `EXP_SCALED_ONE` leaves the principal amount untouched in both directions.
    function testFuzz_getPresentAmount_identityAtScaledOne(uint112 principal) external view {
        assertEq(indexingMath.getPresentAmountRoundedDown(principal, _EXP_SCALED_ONE), principal);
        assertEq(indexingMath.getPresentAmountRoundedUp(principal, _EXP_SCALED_ONE), principal);
    }

    function testFuzz_getPrincipalAmount_identityAtScaledOne(uint112 principal) external view {
        assertEq(indexingMath.getPrincipalAmountRoundedDown(principal, _EXP_SCALED_ONE), principal);
        assertEq(indexingMath.getPrincipalAmountRoundedUp(principal, _EXP_SCALED_ONE), principal);
    }

    /// @dev Rounding up is never below rounding down, and never more than one unit above it.
    function testFuzz_getPresentAmount_roundedUpIsAtMostOneAboveRoundedDown(
        uint112 principal,
        uint128 index
    ) external view {
        uint256 roundedDown = indexingMath.getPresentAmountRoundedDown(principal, index);
        uint256 roundedUp = indexingMath.getPresentAmountRoundedUp(principal, index);

        assertGe(roundedUp, roundedDown);
        assertLe(roundedUp - roundedDown, 1);
    }

    function testFuzz_getPrincipalAmount_roundedUpIsAtMostOneAboveRoundedDown(
        uint256 presentAmount,
        uint128 index
    ) external view {
        index = uint128(bound(index, _EXP_SCALED_ONE, type(uint128).max));
        presentAmount = bound(presentAmount, 0, uint256(type(uint112).max) / _EXP_SCALED_ONE);

        uint112 roundedDown = indexingMath.getPrincipalAmountRoundedDown(presentAmount, index);
        uint112 roundedUp = indexingMath.getPrincipalAmountRoundedUp(presentAmount, index);

        assertGe(roundedUp, roundedDown);
        assertLe(roundedUp - roundedDown, 1);
    }

    /// @dev The largest reachable present amount is `(2^112 - 1) * (2^128 - 1) / 1e12`, roughly 1.77e60, which is
    ///      twelve orders of magnitude below `type(uint240).max`. The uint256 return type is therefore never needed.
    function test_getPresentAmount_alwaysFitsUInt240() external view {
        assertLt(indexingMath.getPresentAmountRoundedUp(type(uint112).max, type(uint128).max), type(uint240).max);
    }

    function testFuzz_getPresentAmount_alwaysFitsUInt240(uint112 principal, uint128 index) external view {
        assertLe(indexingMath.getPresentAmountRoundedDown(principal, index), type(uint240).max);
        assertLe(indexingMath.getPresentAmountRoundedUp(principal, index), type(uint240).max);
    }
}
