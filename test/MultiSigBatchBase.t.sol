// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { MockSafe } from "./utils/MockSafe.sol";
import { MultiSigBatchBaseHarness } from "./utils/MultiSigBatchBaseHarness.sol";

contract MultiSigBatchBaseTests is Test {
    MultiSigBatchBaseHarness public harness;
    MockSafe public safe;

    address public owner = makeAddr("owner");
    address public target = makeAddr("target");

    function setUp() external {
        // NOTE: The MultiSend address is resolved per chain, and the mock Safe never calls it.
        vm.chainId(1);

        harness = new MultiSigBatchBaseHarness();

        address[] memory owners_ = new address[](1);
        owners_[0] = owner;

        safe = new MockSafe(owners_);
    }

    /* ============ _simulateBatch ============ */

    function test_simulateBatch_leavesStateUntouched() external {
        harness.addToBatch(target, "");

        harness.simulateBatch(address(safe));

        assertEq(safe.nonce(), 0);
        assertEq(owner.balance, 0);
    }
}
