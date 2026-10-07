// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { HTTP } from "../lib/safe-utils/lib/solidity-http/src/HTTP.sol";

import { Test } from "../lib/forge-std/src/Test.sol";

import { SafeNonce } from "../script/SafeNonce.sol";

import { SafeNonceHarness } from "./utils/SafeNonceHarness.sol";

contract SafeNonceTests is Test {
    SafeNonceHarness public harness;

    function setUp() external {
        harness = new SafeNonceHarness();
    }

    /* ============ fromResponse ============ */

    function test_fromResponse_statusBelow2xx() external {
        vm.expectRevert(abi.encodeWithSelector(SafeNonce.PendingProposalsQueryFailed.selector, 199, "early"));
        harness.fromResponse(3, HTTP.Response({ status: 199, data: "early" }));
    }

    function test_fromResponse_statusAbove2xx() external {
        vm.expectRevert(abi.encodeWithSelector(SafeNonce.PendingProposalsQueryFailed.selector, 300, "moved"));
        harness.fromResponse(3, HTTP.Response({ status: 300, data: "moved" }));
    }

    function test_fromResponse_noPending() external view {
        assertEq(harness.fromResponse(3, HTTP.Response({ status: 200, data: _pending(0, 0) })), 3);
    }

    function test_fromResponse_pendingAboveOnChain() external view {
        assertEq(harness.fromResponse(3, HTTP.Response({ status: 299, data: _pending(2, 4) })), 5);
    }

    function test_fromResponse_pendingAtOnChain() external view {
        assertEq(harness.fromResponse(3, HTTP.Response({ status: 200, data: _pending(1, 3) })), 4);
    }

    /// @dev A stale proposal below the on-chain nonce (the loser of a past collision) must not lower the nonce.
    function test_fromResponse_pendingBelowOnChain() external view {
        assertEq(harness.fromResponse(7, HTTP.Response({ status: 200, data: _pending(1, 3) })), 7);
    }

    function testFuzz_fromResponse_pending(uint256 onChain_, uint256 count_, uint256 highest_) external view {
        onChain_ = bound(onChain_, 0, type(uint128).max);
        count_ = bound(count_, 1, type(uint128).max);
        highest_ = bound(highest_, 0, type(uint128).max);

        uint256 expected_ = highest_ + 1 > onChain_ ? highest_ + 1 : onChain_;

        assertEq(
            harness.fromResponse(onChain_, HTTP.Response({ status: 200, data: _pending(count_, highest_) })),
            expected_
        );
    }

    /// @dev    Builds a transaction service page like the real `multisig-transactions` listing, ordered by nonce descending.
    /// @param  count_   The total number of pending proposals.
    /// @param  highest_ The nonce of the first (highest) result, ignored when `count_` is zero.
    /// @return The JSON body.
    function _pending(uint256 count_, uint256 highest_) internal pure returns (string memory) {
        string memory results_ = count_ == 0
            ? "[]"
            : string.concat(
                '[{"safe":"0x0000000000000000000000000000000000000001","nonce":',
                vm.toString(highest_),
                "}]"
            );

        return
            string.concat('{"count":', vm.toString(count_), ',"next":null,"previous":null,"results":', results_, "}");
    }
}
