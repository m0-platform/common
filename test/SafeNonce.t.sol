// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { SafeNonce } from "../script/SafeNonce.sol";

contract SafeNonceTests is Test {
    function test_nextFrom_noPending() external pure {
        assertEq(SafeNonce.nextFrom(3, 0, 0), 3);
    }

    function test_nextFrom_pendingAtOrAboveOnChain() external pure {
        assertEq(SafeNonce.nextFrom(3, 2, 4), 5);
        assertEq(SafeNonce.nextFrom(3, 1, 3), 4);
    }

    function test_nextFrom_pendingBelowOnChain() external pure {
        assertEq(SafeNonce.nextFrom(7, 1, 2), 7);
    }
}
