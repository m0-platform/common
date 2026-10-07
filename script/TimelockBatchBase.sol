// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import {
    TimelockController
} from "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";
import { Script } from "../lib/forge-std/src/Script.sol";

abstract contract TimelockBatchBase is Script {
    address[] internal _timelockTargets;
    uint256[] internal _timelockValues;
    bytes[] internal _timelockPayloads;

    /// @notice Thrown in case an operation is tried to be executed but isn't ready yet.
    /// @param id_ The hashed operation identifier.
    error OperationNotReady(bytes32 id_);

    /// @notice Adds a new transaction with no sent value to the timelock call stack.
    /// @param target_ The address of the contract to interact with.
    /// @param payload_ The transaction payload.
    function _addToTimelockBatch(address target_, bytes memory payload_) internal {
        _timelockTargets.push(target_);
        _timelockValues.push(0);
        _timelockPayloads.push(payload_);
    }

    /// @notice Adds a new combination of target contract, sent value, and transaction payload to the timelock call stack.
    /// @param target_ The address of the contract to interact with.
    /// @param value_ The value to send along with the transaction.
    /// @param payload_ The transaction payload.
    function _addToTimelockBatch(address target_, uint256 value_, bytes memory payload_) internal {
        _timelockTargets.push(target_);
        _timelockValues.push(value_);
        _timelockPayloads.push(payload_);
    }

    /// @notice Executes a previously scheduled timelock batch after the delay has elapsed.
    /// @param  target_ The address of the TimelockController.
    /// @param  predecessor_  The predecessor operation id, or bytes32(0) if none.
    /// @param  salt_     The salt used when scheduling the timelock operation.
    function _executeTimelockBatch(address target_, bytes32 predecessor_, bytes32 salt_) internal {
        TimelockController timelock = TimelockController(payable(target_));

        bytes32 id = _getOperationBatchId(target_, predecessor_, salt_);

        if (!timelock.isOperationReady(id)) {
            revert OperationNotReady(id);
        }

        timelock.executeBatch(_timelockTargets, _timelockValues, _timelockPayloads, predecessor_, salt_);
    }

    /// @notice Returns the operation id of the accumulated batch, as hashed by the TimelockController.
    /// @param  target_ The address of the TimelockController.
    /// @param  predecessor_  The predecessor operation id, or bytes32(0) if none.
    /// @param  salt_     The salt used when scheduling the timelock operation.
    function _getOperationBatchId(
        address target_,
        bytes32 predecessor_,
        bytes32 salt_
    ) internal view returns (bytes32) {
        return TimelockController(payable(target_)).hashOperationBatch(
            _timelockTargets,
            _timelockValues,
            _timelockPayloads,
            predecessor_,
            salt_
        );
    }

    /// @notice Builds the calldata to schedule a batch of transactions on the timelock.
    /// @param predecessor_ The predecessor operation id, or bytes32(0) if none.
    /// @param salt_ The salt used when scheduling the timelock operation.
    /// @param delay_ The delay with which to schedule the transaction execution.
    function _getScheduleBatchCallData(
        bytes32 predecessor_,
        bytes32 salt_,
        uint256 delay_
    ) internal view returns (bytes memory) {
        return abi.encodeCall(
            TimelockController.scheduleBatch,
            (_timelockTargets, _timelockValues, _timelockPayloads, predecessor_, salt_, delay_)
        );
    }

    /// @notice Simulates the timelock execution based on the accumulated call stack.
    /// @param timelock_ The address of the timelock contract to execute from.
    function _simulateBatch(address timelock_) internal {
        uint256 snapshot_ = vm.snapshotState();

        vm.startPrank(timelock_);

        for (uint256 i = 0; i < _timelockTargets.length; i++) {
            (bool success, ) = _timelockTargets[i].call{ value: _timelockValues[i] }(_timelockPayloads[i]);
            require(success, "Simulation failed");
        }

        vm.stopPrank();

        // NOTE: The simulation executes the batch for real on the local fork. Restoring the state keeps the
        //       proposal built from the current chain state, e.g. the timelock's minimum delay.
        require(vm.revertToStateAndDelete(snapshot_), "State restore failed");
    }
}
