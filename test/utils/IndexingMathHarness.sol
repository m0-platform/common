// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import {IndexingMath} from "../../src/libs/IndexingMath.sol";

// Note: This harness contract is needed because internal library functions can be inlined by the compiler
//       and won't be picked up by forge coverage
// See: https://github.com/foundry-rs/foundry/issues/6308#issuecomment-1866878768
contract IndexingMathHarness {
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

    function getSafePrincipalAmountRoundedUp(uint256 presentAmount, uint128 index, uint112 maxPrincipalAmount)
        external
        pure
        returns (uint112)
    {
        return IndexingMath.getSafePrincipalAmountRoundedUp(presentAmount, index, maxPrincipalAmount);
    }
}
