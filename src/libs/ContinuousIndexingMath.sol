// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

/**
 * @title  Arithmetic library with operations for calculating continuous indexing.
 * @author M0 Labs
 */
library ContinuousIndexingMath {
    /* ============ Variables ============ */

    /// @notice The scaling of indexes for exponent math.
    uint56 internal constant EXP_SCALED_ONE = 1e12;

    /// @notice The number of seconds in a year.
    uint32 internal constant SECONDS_PER_YEAR = 31_536_000;

    /// @notice 100% in basis points.
    uint16 internal constant BPS_SCALED_ONE = 1e4;

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @notice Helper function to calculate `(index * deltaIndex) / EXP_SCALED_ONE`, rounded down.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function multiplyIndicesDown(uint128 index, uint48 deltaIndex) internal pure returns (uint144) {
        return uint144((uint256(index) * deltaIndex) / EXP_SCALED_ONE);
    }

    /**
     * @notice Helper function to calculate `(index * deltaIndex) / EXP_SCALED_ONE`, rounded up.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function multiplyIndicesUp(uint128 index, uint48 deltaIndex) internal pure returns (uint144) {
        return uint144((uint256(index) * deltaIndex + (EXP_SCALED_ONE - 1)) / EXP_SCALED_ONE);
    }

    /**
     * @notice Helper function to calculate e^rt (continuous compounding formula).
     * @dev    `uint64 yearlyRate` can accommodate 1000% interest per year.
     * @dev    `uint32 time` can accommodate 100 years.
     * @dev    `type(uint64).max * type(uint32).max / SECONDS_PER_YEAR` fits in a `uint72`.
     */
    function getContinuousIndex(uint64 yearlyRate, uint32 time) internal pure returns (uint48) {
        return exponent(uint72((uint256(yearlyRate) * time) / SECONDS_PER_YEAR));
    }

    /**
     * @notice Helper function to calculate y = e^x using R(4,4) Padé approximation:
     *           e(x) = (1 + x/2 + 3(x^2)/28 + x^3/84 + x^4/1680) / (1 - x/2 + 3(x^2)/28 - x^3/84 + x^4/1680)
     *           See: https://en.wikipedia.org/wiki/Pad%C3%A9_table
     *           See: https://www.wolframalpha.com/input?i=PadeApproximant%5Bexp%5Bx%5D%2C%7Bx%2C0%2C%7B4%2C+4%7D%7D%5D
     *         Despite itself being a whole number, `x` represents a real number scaled by `EXP_SCALED_ONE`, thus
     *         allowing for y = e^x where x is a real number.
     * @dev    Output for a `uint72` input `x` will fit in `uint48`
     */
    function exponent(uint72 x) internal pure returns (uint48) {
        uint256 x2 = uint256(x) * x;

        // `additiveTerms` is `(1 + 3(x^2)/28 + x^4/1680)`, and scaled by `84e27`.
        // NOTE: `84e27` the cleanest and largest scalar, given the various intermediate overflow possibilities.
        // NOTE: The resulting `(x2 * x2) / 20e21` term has been split to avoid overflow of `x2 * x2`.
        uint256 additiveTerms = 84e27 + (9e3 * x2) + ((x2 / 2e11) * (x2 / 1e11));

        // `differentTerms` is `(- x/2 - x^3/84)`, but positive (will be subtracted later), and scaled by `84e27`.
        uint256 differentTerms = uint256(x) * (42e15 + (x2 / 1e9));

        // Result needs to be scaled by `1e12`.
        // NOTE: Can cast to `uint48` because contents can never be larger than `type(uint48).max` for any `x`.
        //       Max `y` is ~200e12, before falling off. See links above for reference.
        return uint48(((additiveTerms + differentTerms) * 1e12) / (additiveTerms - differentTerms));
    }

    /**
     * @notice Helper function to convert a scaled 12-decimal percentage to basis points.
     * @param  input A percentage represented as a scaled 12-decimal number.
     * @return The percentage represented as basis points.
     */
    function convertToBasisPoints(uint64 input) internal pure returns (uint40) {
        return uint40((uint256(input) * BPS_SCALED_ONE) / EXP_SCALED_ONE);
    }

    /**
     * @notice Helper function to convert basis points to a scaled 12-decimal percentage.
     * @param  input A percentage represented as basis points.
     * @return The percentage represented as a scaled 12-decimal number.
     */
    function convertFromBasisPoints(uint32 input) internal pure returns (uint64) {
        return uint64((uint256(input) * EXP_SCALED_ONE) / BPS_SCALED_ONE);
    }
}
