// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { ContinuousIndexingMath } from "../src/libs/ContinuousIndexingMath.sol";
import { IndexingMath } from "../src/libs/IndexingMath.sol";

import { ContinuousIndexingMathHarness } from "./utils/ContinuousIndexingMathHarness.sol";

contract ContinuousIndexingMathTests is Test {
    uint56 internal constant _EXP_SCALED_ONE = ContinuousIndexingMath.EXP_SCALED_ONE;

    ContinuousIndexingMathHarness public continuousIndexingMath;

    function setUp() external {
        continuousIndexingMath = new ContinuousIndexingMathHarness();
    }

    function test_exponent() external view {
        assertEq(continuousIndexingMath.exponent(0), 1_000000000000); // actual 1

        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE / 10000), 1_000100005000); // actual 1.0001000050001667
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE / 1000), 1_001000500166); // actual 1.0010005001667084
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE / 100), 1_010050167084); // actual 1.010050167084168
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE / 10), 1_105170918075); // actual 1.1051709180756477
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE / 2), 1_648721270572); // actual 1.6487212707001282
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE), 2_718281718281); // actual 2.718281828459045
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE * 2), 7_388888888888); // actual 7.3890560989306495

        // Demonstrate maximum of ~200e12.
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE * 5), 128_619047619047);
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE * 6), 196_000000000000);
        assertEq(continuousIndexingMath.exponent(_EXP_SCALED_ONE * 7), 159_260869565217);

        // If `unchecked` is removed from `exponent`, it will not overflow (lot's of error nonetheless).
        assertEq(continuousIndexingMath.exponent(type(uint72).max), 1_000000008470);
    }

    function test_getContinuousIndex() external view {
        assertEq(continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 0), 1_000000000000); // 1
        assertEq(continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 1 days), 1_002743482506); // 1.00274348
        assertEq(continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 10 days), 1_027776016255); // 1.02777602
        assertEq(continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 365 days), 2718281718281); // 2.71828183
    }

    function test_multiplyContinuousRates() external {
        uint256 oneHourRate = continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 1 hours);
        uint256 twoHourRate = continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 2 hours);
        uint256 fourHourRate = continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 4 hours);
        uint256 sixteenHourRate = continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 16 hours);
        uint256 oneDayRate = continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 1 days);
        uint256 twoDayRate = continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 2 days);

        uint256 oneInExp = uint256(_EXP_SCALED_ONE);

        assertEqPrecision((oneHourRate * oneHourRate) / oneInExp, twoHourRate, 1e1);

        assertEqPrecision(
            (oneHourRate * oneHourRate * oneHourRate * oneHourRate) / (oneInExp * oneInExp * oneInExp),
            fourHourRate,
            1e2
        );

        assertEqPrecision(
            (fourHourRate * fourHourRate * fourHourRate * fourHourRate) / (oneInExp * oneInExp * oneInExp),
            sixteenHourRate,
            1e1
        );

        assertEqPrecision((sixteenHourRate * fourHourRate * fourHourRate) / (oneInExp * oneInExp), oneDayRate, 1e1);

        assertEqPrecision(
            (sixteenHourRate * sixteenHourRate * sixteenHourRate) / (oneInExp * oneInExp),
            twoDayRate,
            1e1
        );

        assertEqPrecision((oneDayRate * oneDayRate) / oneInExp, twoDayRate, 1e1);
    }

    /// @dev The tests below feed `ContinuousIndexingMath` indices straight into `IndexingMath`, which is only sound
    ///      while both libraries scale by the same one.
    function test_expScaledOneMatchesIndexingMath() external pure {
        assertEq(ContinuousIndexingMath.EXP_SCALED_ONE, IndexingMath.EXP_SCALED_ONE);
    }

    function test_multiplyThenDivide_100apy() external view {
        uint112 amount = 1_000e6;
        uint128 sevenDayRate = continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 7 days);
        uint128 thirtyDayRate = continuousIndexingMath.getContinuousIndex(_EXP_SCALED_ONE, 30 days);

        assertEq(
            IndexingMath.getPrincipalAmountRoundedDown(
                IndexingMath.getPresentAmountRoundedDown(amount, sevenDayRate),
                sevenDayRate
            ),
            amount - 1
        );
        assertEq(
            IndexingMath.getPresentAmountRoundedDown(
                IndexingMath.getPrincipalAmountRoundedDown(amount, sevenDayRate),
                sevenDayRate
            ),
            amount - 1
        );

        assertEq(
            IndexingMath.getPrincipalAmountRoundedDown(
                IndexingMath.getPresentAmountRoundedDown(amount, thirtyDayRate),
                thirtyDayRate
            ),
            amount - 1
        );
        assertEq(
            IndexingMath.getPresentAmountRoundedDown(
                IndexingMath.getPrincipalAmountRoundedDown(amount, thirtyDayRate),
                thirtyDayRate
            ),
            amount - 1
        );
    }

    function test_multiplyThenDivide_6apy() external view {
        uint112 amount = 1_000e6;
        uint128 sevenDayRate = continuousIndexingMath.getContinuousIndex((_EXP_SCALED_ONE * 6) / 100, 7 days);
        uint128 thirtyDayRate = continuousIndexingMath.getContinuousIndex((_EXP_SCALED_ONE * 6) / 100, 30 days);

        assertEq(
            IndexingMath.getPrincipalAmountRoundedDown(
                IndexingMath.getPresentAmountRoundedDown(amount, sevenDayRate),
                sevenDayRate
            ),
            amount - 1
        );
        assertEq(
            IndexingMath.getPresentAmountRoundedDown(
                IndexingMath.getPrincipalAmountRoundedDown(amount, sevenDayRate),
                sevenDayRate
            ),
            amount - 1
        );

        assertEq(
            IndexingMath.getPrincipalAmountRoundedDown(
                IndexingMath.getPresentAmountRoundedDown(amount, thirtyDayRate),
                thirtyDayRate
            ),
            amount - 1
        );
        assertEq(
            IndexingMath.getPresentAmountRoundedDown(
                IndexingMath.getPrincipalAmountRoundedDown(amount, thirtyDayRate),
                thirtyDayRate
            ),
            amount - 1
        );
    }

    function test_convertToBasisPoints() external view {
        assertEq(continuousIndexingMath.convertToBasisPoints(1_000000000000), 10_000);
        assertEq(continuousIndexingMath.convertToBasisPoints(type(uint64).max), 184467440_737);
    }

    function test_convertFromBasisPoints() external view {
        assertEq(continuousIndexingMath.convertFromBasisPoints(10_000), 1_000000000000);
        assertEq(continuousIndexingMath.convertFromBasisPoints(type(uint32).max), 429496_729500000000);
    }

    function test_exponentLimits() external view {
        uint72 x = 6_101171897009;
        uint48 maxExponent = 196_691035579298;

        assertEq(continuousIndexingMath.exponent(x), maxExponent); // Max of exponent.

        assertLe(continuousIndexingMath.exponent(x - 1), maxExponent);
        assertLe(continuousIndexingMath.exponent(x - 10), maxExponent);
        assertLe(continuousIndexingMath.exponent(x - 100), maxExponent);
        assertLe(continuousIndexingMath.exponent(x - 1000), maxExponent);
        assertLe(continuousIndexingMath.exponent(x - 10000), maxExponent);
        assertLe(continuousIndexingMath.exponent(x - 100000), maxExponent);
        assertLe(continuousIndexingMath.exponent(x - 1000000), maxExponent);

        assertLe(continuousIndexingMath.exponent(x + 1), maxExponent);
        assertLe(continuousIndexingMath.exponent(x + 10), maxExponent);
        assertLe(continuousIndexingMath.exponent(x + 100), maxExponent);
        assertLe(continuousIndexingMath.exponent(x + 1000), maxExponent);
        assertLe(continuousIndexingMath.exponent(x + 10000), maxExponent);
        assertLe(continuousIndexingMath.exponent(x + 100000), maxExponent);
        assertLe(continuousIndexingMath.exponent(x + 1000000), maxExponent);

        uint256 maxYearlyRateGivenHourlyUpdates = (x * 365 days) / 1 hours;
        uint256 maxYearlyRateGivenYearlyUpdates = (x * 365 days) / 365 days;

        assertEq(maxYearlyRateGivenHourlyUpdates, 53446_265817798840); // 5,344,626%
        assertEq(maxYearlyRateGivenYearlyUpdates, 6_101171897009); // 610%

        assertTrue(maxYearlyRateGivenHourlyUpdates < type(uint64).max);
        assertTrue(maxYearlyRateGivenYearlyUpdates < type(uint64).max);

        assertEq(continuousIndexingMath.convertToBasisPoints(uint64(maxYearlyRateGivenHourlyUpdates)), 534462_658); // 5,344,626.58%
        assertEq(continuousIndexingMath.convertToBasisPoints(uint64(maxYearlyRateGivenYearlyUpdates)), 61_011); // 610.11%

        assertEq(
            continuousIndexingMath.getContinuousIndex(uint64(maxYearlyRateGivenHourlyUpdates), 1 hours),
            maxExponent
        );
        assertEq(
            continuousIndexingMath.getContinuousIndex(uint64(maxYearlyRateGivenYearlyUpdates), 365 days),
            maxExponent
        );
    }

    function test_indexLimits_hourlyAt1000APY() external view {
        // 6 years of hourly updates at 1000% APY.
        uint128 index = _EXP_SCALED_ONE;

        for (uint256 i; i < 52_560; ++i) {
            index = uint128(
                continuousIndexingMath.multiplyIndicesDown(
                    index,
                    continuousIndexingMath.getContinuousIndex(
                        continuousIndexingMath.convertFromBasisPoints(100_000), // 1000%
                        1 hours
                    )
                )
            );
        }
    }

    function test_indexLimits_dailyAt100APY() external view {
        // 60 years of daily updates at 100% APY.
        uint128 index = _EXP_SCALED_ONE;

        for (uint256 i; i < 21_900; ++i) {
            index = uint128(
                continuousIndexingMath.multiplyIndicesDown(
                    index,
                    continuousIndexingMath.getContinuousIndex(
                        continuousIndexingMath.convertFromBasisPoints(10_000), // 100%
                        1 days
                    )
                )
            );
        }
    }

    function test_indexLimits_dailyAt10APY() external view {
        // 100 years of daily updates at 10% APY.
        uint128 index = _EXP_SCALED_ONE;

        for (uint256 i; i < 36_500; ++i) {
            index = uint128(
                continuousIndexingMath.multiplyIndicesDown(
                    index,
                    continuousIndexingMath.getContinuousIndex(
                        continuousIndexingMath.convertFromBasisPoints(1_000), // 10%
                        1 days
                    )
                )
            );
        }
    }

    function assertEqPrecision(uint256 a_, uint256 b_, uint256 precision_) internal {
        if (a_ / precision_ != b_ / precision_) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("      Left", a_);
            emit log_named_uint("     Right", b_);
            fail();
        }
    }
}
