// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";

import {IndexingMath} from "../src/libs/IndexingMath.sol";
import {UIntMath} from "../src/libs/UIntMath.sol";

import {IndexingMathHarness} from "./utils/IndexingMathHarness.sol";

contract IndexingMathTests is Test {
    uint56 internal constant _EXP_SCALED_ONE = IndexingMath.EXP_SCALED_ONE;

    IndexingMathHarness internal _indexingMath = new IndexingMathHarness();

    /* ============ getPresentAmountRoundedDown ============ */

    function test_getPresentAmountRoundedDown() external view {
        // An index of `EXP_SCALED_ONE` is the identity.
        assertEq(_indexingMath.getPresentAmountRoundedDown(0, _EXP_SCALED_ONE), 0);
        assertEq(_indexingMath.getPresentAmountRoundedDown(1, _EXP_SCALED_ONE), 1);
        assertEq(_indexingMath.getPresentAmountRoundedDown(1_000e6, _EXP_SCALED_ONE), 1_000e6);

        // Indexes above and below `EXP_SCALED_ONE`.
        assertEq(_indexingMath.getPresentAmountRoundedDown(1_000e6, 2 * _EXP_SCALED_ONE), 2_000e6);
        assertEq(_indexingMath.getPresentAmountRoundedDown(1_000e6, (11 * _EXP_SCALED_ONE) / 10), 1_100e6);
        assertEq(_indexingMath.getPresentAmountRoundedDown(1_000e6, _EXP_SCALED_ONE / 2), 500e6);

        // Truncation towards zero.
        assertEq(_indexingMath.getPresentAmountRoundedDown(1, _EXP_SCALED_ONE - 1), 0);
        assertEq(_indexingMath.getPresentAmountRoundedDown(1, _EXP_SCALED_ONE + 1), 1);
        assertEq(_indexingMath.getPresentAmountRoundedDown(1, 1), 0);
        assertEq(_indexingMath.getPresentAmountRoundedDown(3, _EXP_SCALED_ONE / 3), 0);
        assertEq(_indexingMath.getPresentAmountRoundedDown(0, type(uint128).max), 0);

        // A zero index yields a zero present amount.
        assertEq(_indexingMath.getPresentAmountRoundedDown(1_000e6, 0), 0);

        // The maximum inputs do not overflow, since `type(uint112).max * type(uint128).max` fits in a `uint256`.
        assertEq(
            _indexingMath.getPresentAmountRoundedDown(type(uint112).max, type(uint128).max),
            (uint256(type(uint112).max) * type(uint128).max) / _EXP_SCALED_ONE
        );
    }

    /* ============ getPresentAmountRoundedUp ============ */

    function test_getPresentAmountRoundedUp() external view {
        // An index of `EXP_SCALED_ONE` is the identity.
        assertEq(_indexingMath.getPresentAmountRoundedUp(0, _EXP_SCALED_ONE), 0);
        assertEq(_indexingMath.getPresentAmountRoundedUp(1, _EXP_SCALED_ONE), 1);
        assertEq(_indexingMath.getPresentAmountRoundedUp(1_000e6, _EXP_SCALED_ONE), 1_000e6);

        // Indexes above and below `EXP_SCALED_ONE`.
        assertEq(_indexingMath.getPresentAmountRoundedUp(1_000e6, 2 * _EXP_SCALED_ONE), 2_000e6);
        assertEq(_indexingMath.getPresentAmountRoundedUp(1_000e6, (11 * _EXP_SCALED_ONE) / 10), 1_100e6);
        assertEq(_indexingMath.getPresentAmountRoundedUp(1_000e6, _EXP_SCALED_ONE / 2), 500e6);

        // Truncation away from zero. Different than `getPresentAmountRoundedDown`.
        assertEq(_indexingMath.getPresentAmountRoundedUp(1, _EXP_SCALED_ONE - 1), 1);
        assertEq(_indexingMath.getPresentAmountRoundedUp(1, _EXP_SCALED_ONE + 1), 2);
        assertEq(_indexingMath.getPresentAmountRoundedUp(1, 1), 1);
        assertEq(_indexingMath.getPresentAmountRoundedUp(3, _EXP_SCALED_ONE / 3), 1);

        // A zero principal is never rounded up to a non-zero present amount.
        assertEq(_indexingMath.getPresentAmountRoundedUp(0, type(uint128).max), 0);

        // A zero index yields a zero present amount.
        assertEq(_indexingMath.getPresentAmountRoundedUp(1_000e6, 0), 0);

        // The maximum inputs do not overflow.
        assertEq(
            _indexingMath.getPresentAmountRoundedUp(type(uint112).max, type(uint128).max),
            ((uint256(type(uint112).max) * type(uint128).max) + (_EXP_SCALED_ONE - 1)) / _EXP_SCALED_ONE
        );
    }

    /* ============ getPrincipalAmountRoundedDown ============ */

    function test_getPrincipalAmountRoundedDown() external view {
        // An index of `EXP_SCALED_ONE` is the identity.
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(0, _EXP_SCALED_ONE), 0);
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(1, _EXP_SCALED_ONE), 1);
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(1_000e6, _EXP_SCALED_ONE), 1_000e6);

        // Indexes above and below `EXP_SCALED_ONE`.
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(2_000e6, 2 * _EXP_SCALED_ONE), 1_000e6);
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(1_000e6, (11 * _EXP_SCALED_ONE) / 10), 909_090909);
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(500e6, _EXP_SCALED_ONE / 2), 1_000e6);

        // Truncation towards zero.
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(1, _EXP_SCALED_ONE + 1), 0);
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(1, 2 * _EXP_SCALED_ONE), 0);
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(1, 3 * _EXP_SCALED_ONE), 0);
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(10, 3 * _EXP_SCALED_ONE), 3);

        // The largest representable principal.
        assertEq(_indexingMath.getPrincipalAmountRoundedDown(type(uint112).max, _EXP_SCALED_ONE), type(uint112).max);
    }

    function test_getPrincipalAmountRoundedDown_divisionByZero() external {
        vm.expectRevert(IndexingMath.DivisionByZero.selector);
        _indexingMath.getPrincipalAmountRoundedDown(1_000e6, 0);
    }

    function test_getPrincipalAmountRoundedDown_invalidUInt112() external {
        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        _indexingMath.getPrincipalAmountRoundedDown(uint256(type(uint112).max) + 1, _EXP_SCALED_ONE);
    }

    function test_getPrincipalAmountRoundedDown_overflow() external {
        // `presentAmount * EXP_SCALED_ONE` overflows before the division can take place.
        vm.expectRevert(stdError.arithmeticError);
        _indexingMath.getPrincipalAmountRoundedDown(type(uint256).max, type(uint128).max);
    }

    /* ============ getPrincipalAmountRoundedUp ============ */

    function test_getPrincipalAmountRoundedUp() external view {
        // An index of `EXP_SCALED_ONE` is the identity.
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(0, _EXP_SCALED_ONE), 0);
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(1, _EXP_SCALED_ONE), 1);
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(1_000e6, _EXP_SCALED_ONE), 1_000e6);

        // Indexes above and below `EXP_SCALED_ONE`.
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(2_000e6, 2 * _EXP_SCALED_ONE), 1_000e6);
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(1_000e6, (11 * _EXP_SCALED_ONE) / 10), 909_090910);
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(500e6, _EXP_SCALED_ONE / 2), 1_000e6);

        // Truncation away from zero. Different than `getPrincipalAmountRoundedDown`.
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(1, _EXP_SCALED_ONE + 1), 1);
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(1, 2 * _EXP_SCALED_ONE), 1);
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(1, 3 * _EXP_SCALED_ONE), 1);
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(10, 3 * _EXP_SCALED_ONE), 4);

        // A zero present amount is never rounded up to a non-zero principal.
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(0, type(uint128).max), 0);

        // The largest representable principal.
        assertEq(_indexingMath.getPrincipalAmountRoundedUp(type(uint112).max, _EXP_SCALED_ONE), type(uint112).max);
    }

    function test_getPrincipalAmountRoundedUp_divisionByZero() external {
        vm.expectRevert(IndexingMath.DivisionByZero.selector);
        _indexingMath.getPrincipalAmountRoundedUp(1_000e6, 0);
    }

    function test_getPrincipalAmountRoundedUp_invalidUInt112() external {
        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        _indexingMath.getPrincipalAmountRoundedUp(uint256(type(uint112).max) + 1, _EXP_SCALED_ONE);
    }

    function test_getPrincipalAmountRoundedUp_overflow() external {
        // `presentAmount * EXP_SCALED_ONE` overflows before the division can take place.
        vm.expectRevert(stdError.arithmeticError);
        _indexingMath.getPrincipalAmountRoundedUp(type(uint256).max, type(uint128).max);
    }

    /* ============ getSafePrincipalAmountRoundedUp ============ */

    function test_getSafePrincipalAmountRoundedUp() external view {
        // Below the cap, the result matches `getPrincipalAmountRoundedUp`.
        assertEq(_indexingMath.getSafePrincipalAmountRoundedUp(0, _EXP_SCALED_ONE, 1_000e6), 0);
        assertEq(_indexingMath.getSafePrincipalAmountRoundedUp(1, _EXP_SCALED_ONE, 1_000e6), 1);
        assertEq(_indexingMath.getSafePrincipalAmountRoundedUp(10, 3 * _EXP_SCALED_ONE, 1_000e6), 4);

        // Exactly at the cap.
        assertEq(_indexingMath.getSafePrincipalAmountRoundedUp(1_000e6, _EXP_SCALED_ONE, 1_000e6), 1_000e6);

        // Above the cap.
        assertEq(_indexingMath.getSafePrincipalAmountRoundedUp(1_000e6, _EXP_SCALED_ONE, 999e6), 999e6);
        assertEq(_indexingMath.getSafePrincipalAmountRoundedUp(1_000e6, _EXP_SCALED_ONE, 0), 0);

        // The cap applies to the rounded up amount, not the rounded down one.
        assertEq(_indexingMath.getSafePrincipalAmountRoundedUp(10, 3 * _EXP_SCALED_ONE, 3), 3);
    }

    function test_getSafePrincipalAmountRoundedUp_divisionByZero() external {
        vm.expectRevert(IndexingMath.DivisionByZero.selector);
        _indexingMath.getSafePrincipalAmountRoundedUp(1_000e6, 0, 1_000e6);
    }

    function test_getSafePrincipalAmountRoundedUp_invalidUInt112() external {
        // NOTE: The cap is applied after the `uint112` cast, so a present amount whose principal does not fit in a
        //       `uint112` reverts rather than being capped at `maxPrincipalAmount`.
        vm.expectRevert(UIntMath.InvalidUInt112.selector);
        _indexingMath.getSafePrincipalAmountRoundedUp(uint256(type(uint112).max) + 1, _EXP_SCALED_ONE, 1_000e6);
    }

    /* ============ Fuzz Tests ============ */

    function testFuzz_presentAmountRounding(uint112 principal, uint128 index) external view {
        uint256 roundedDown_ = _indexingMath.getPresentAmountRoundedDown(principal, index);
        uint256 roundedUp_ = _indexingMath.getPresentAmountRoundedUp(principal, index);

        assertGe(roundedUp_, roundedDown_);
        assertLe(roundedUp_ - roundedDown_, 1);

        // They only differ when the division is inexact.
        assertEq(roundedUp_ == roundedDown_, (uint256(principal) * index) % _EXP_SCALED_ONE == 0);
    }

    function testFuzz_principalAmountRounding(uint112 principal, uint128 index) external view {
        index = uint128(bound(index, 1, type(uint128).max));

        // NOTE: Deriving the present amount from a principal amount keeps the inverse within `uint112` bounds.
        uint256 presentAmount_ = _indexingMath.getPresentAmountRoundedDown(principal, index);

        uint112 roundedDown_ = _indexingMath.getPrincipalAmountRoundedDown(presentAmount_, index);
        uint112 roundedUp_ = _indexingMath.getPrincipalAmountRoundedUp(presentAmount_, index);

        assertGe(roundedUp_, roundedDown_);
        assertLe(roundedUp_ - roundedDown_, 1);

        // They only differ when the division is inexact.
        assertEq(roundedUp_ == roundedDown_, (presentAmount_ * _EXP_SCALED_ONE) % index == 0);
    }

    function testFuzz_roundTrip(uint112 principal, uint128 index) external view {
        index = uint128(bound(index, 1, type(uint128).max));

        // Rounding the present amount down and back down can never inflate the principal.
        assertLe(
            _indexingMath.getPrincipalAmountRoundedDown(
                _indexingMath.getPresentAmountRoundedDown(principal, index), index
            ),
            principal
        );

        // NOTE: Rounding up twice can inflate the principal by up to `EXP_SCALED_ONE / index`, so the principal needs
        //       enough headroom below `type(uint112).max` for the result to remain castable to a `uint112`.
        uint112 boundedPrincipal_ = uint112(bound(principal, 0, type(uint112).max - _EXP_SCALED_ONE - 1));

        // Rounding the present amount up and back up can never deflate the principal.
        assertGe(
            _indexingMath.getPrincipalAmountRoundedUp(
                _indexingMath.getPresentAmountRoundedUp(boundedPrincipal_, index), index
            ),
            boundedPrincipal_
        );
    }

    function testFuzz_getSafePrincipalAmountRoundedUp(uint112 principal, uint128 index, uint112 maxPrincipalAmount)
        external
        view
    {
        index = uint128(bound(index, 1, type(uint128).max));

        // NOTE: Deriving the present amount from a principal amount keeps the inverse within `uint112` bounds.
        uint256 presentAmount_ = _indexingMath.getPresentAmountRoundedDown(principal, index);

        uint112 uncapped_ = _indexingMath.getPrincipalAmountRoundedUp(presentAmount_, index);
        uint112 capped_ = _indexingMath.getSafePrincipalAmountRoundedUp(presentAmount_, index, maxPrincipalAmount);

        assertEq(capped_, uncapped_ > maxPrincipalAmount ? maxPrincipalAmount : uncapped_);
        assertLe(capped_, maxPrincipalAmount);
    }
}
