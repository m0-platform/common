// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { TimelockController } from "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

import { TimelockBatchBase } from "../script/TimelockBatchBase.sol";
import { SafeTimelockBatchBase } from "../script/SafeTimelockBatchBase.sol";

import { TimelockBatchBaseHarness } from "./utils/TimelockBatchBaseHarness.sol";

contract TimelockBatchBaseTests is Test {
    uint256 internal constant _MIN_DELAY = 1 days;

    bytes32 internal constant _PREDECESSOR = bytes32(0);
    bytes32 internal constant _SALT = bytes32(uint256(1));

    TimelockBatchBaseHarness internal _harness;
    TimelockController internal _timelock;

    function setUp() external {
        _harness = new TimelockBatchBaseHarness();

        address[] memory proposers = new address[](1);
        proposers[0] = address(this);
        address[] memory executors = new address[](1);
        executors[0] = address(0); // open execution

        _timelock = new TimelockController(_MIN_DELAY, proposers, executors, address(0));
    }

    function test_executeTimelockBatch() external {
        uint256 newDelay = 2 days;

        (address[] memory targets, uint256[] memory values, bytes[] memory payloads) = _updateDelayBatch(newDelay);

        _harness.addToBatch(targets[0], payloads[0]);
        _timelock.scheduleBatch(targets, values, payloads, _PREDECESSOR, _SALT, _MIN_DELAY);

        vm.warp(block.timestamp + _MIN_DELAY + 1);

        _harness.executeBatch(address(_timelock), _PREDECESSOR, _SALT);

        assertEq(_timelock.getMinDelay(), newDelay);
    }

    function test_executeTimelockBatch_revertsIfNotReady() external {
        (address[] memory targets, uint256[] memory values, bytes[] memory payloads) = _updateDelayBatch(2 days);

        _harness.addToBatch(targets[0], payloads[0]);
        _timelock.scheduleBatch(targets, values, payloads, _PREDECESSOR, _SALT, _MIN_DELAY);

        // Delay has not elapsed yet, so the operation is scheduled but not ready.
        bytes32 id = _harness.getOperationBatchId(address(_timelock), _PREDECESSOR, _SALT);

        vm.expectRevert(abi.encodeWithSelector(TimelockBatchBase.OperationNotReady.selector, id));
        _harness.executeBatch(address(_timelock), _PREDECESSOR, _SALT);
    }

    function test_proposeCancel_revertsIfNotPending() external {
        // Nothing scheduled, so the operation is not pending. The revert happens before any Safe call,
        // so a dummy Safe address is enough.
        bytes32 id = _harness.getOperationBatchId(address(_timelock), _PREDECESSOR, _SALT);

        vm.expectRevert(abi.encodeWithSelector(SafeTimelockBatchBase.OperationNotPending.selector, id));
        _harness.proposeCancel(makeAddr("safe"), address(_timelock), address(this), id);
    }

    function test_simulateBatch_leavesStateUntouched() external {
        (address[] memory targets, , bytes[] memory payloads) = _updateDelayBatch(2 days);

        _harness.addToBatch(targets[0], payloads[0]);

        _harness.simulateBatch(address(_timelock));

        assertEq(_timelock.getMinDelay(), _MIN_DELAY);
    }

    function _updateDelayBatch(
        uint256 newDelay_
    ) internal view returns (address[] memory targets_, uint256[] memory values_, bytes[] memory payloads_) {
        targets_ = new address[](1);
        targets_[0] = address(_timelock);
        values_ = new uint256[](1);
        values_[0] = 0;
        payloads_ = new bytes[](1);
        payloads_[0] = abi.encodeCall(TimelockController.updateDelay, (newDelay_));
    }
}
