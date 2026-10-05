// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { SafeNonce } from "./SafeNonce.sol";
import { TimelockBatchBase } from "./TimelockBatchBase.sol";

import { Enum } from "../lib/safe-utils/lib/safe-smart-account/contracts/common/Enum.sol";
import { Safe } from "../lib/safe-utils/src/Safe.sol";
import { TimelockController } from "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

import { console } from "../lib/forge-std/src/console.sol";

abstract contract SafeTimelockBatchBase is TimelockBatchBase {
    using Safe for *;

    Safe.Client internal _safeMultiSig;

    /// @notice Thrown in case a transaction that's supposed to be cancelled is not pending.
    /// @param  id_ The identifier of the transaction.
    error OperationNotPending(bytes32 id_);

    /// @notice Proposes to schedule a batch of transactions to a timelock contract.
    /// @dev    Proposes at the next free Safe nonce. See {SafeNonce-next}.
    /// @param  safe_        The address of the Safe multisig to propose to.
    /// @param  timelock_    The address of the timelock.
    /// @param  sender_      The sender's address.
    /// @param  predecessor_ The predecessor transaction, if any.
    /// @param  salt_        The salt to build the transaction with, if any.
    function _proposeScheduleBatch(
        address safe_,
        address timelock_,
        address sender_,
        bytes32 predecessor_,
        bytes32 salt_
    ) internal {
        bytes memory data_ = _getScheduleBatchData(timelock_, predecessor_, salt_);

        _safeMultiSig.initialize(safe_);
        _proposeToTimelock(timelock_, data_, sender_, SafeNonce.next(_safeMultiSig));
    }

    /// @notice Proposes to schedule a batch of transactions to a timelock contract at an explicit Safe nonce.
    /// @dev    For when the Safe transaction service cannot be queried or the proposal must queue at a chosen position.
    /// @param  safe_        The address of the Safe multisig to propose to.
    /// @param  timelock_    The address of the timelock.
    /// @param  sender_      The sender's address.
    /// @param  predecessor_ The predecessor transaction, if any.
    /// @param  salt_        The salt to build the transaction with, if any.
    /// @param  nonce_       The Safe nonce to propose at.
    function _proposeScheduleBatch(
        address safe_,
        address timelock_,
        address sender_,
        bytes32 predecessor_,
        bytes32 salt_,
        uint256 nonce_
    ) internal {
        bytes memory data_ = _getScheduleBatchData(timelock_, predecessor_, salt_);

        _safeMultiSig.initialize(safe_);
        _proposeToTimelock(timelock_, data_, sender_, nonce_);
    }

    /// @notice Proposes to cancel the execution of a pending message that was originally scheduled through a timelock.
    /// @dev    Proposes at the next free Safe nonce. See {SafeNonce-next}.
    /// @param  safe_     The address of the Safe multisig to propose the transaction to.
    /// @param  timelock_ The address of the timelock.
    /// @param  sender_   The sender's address.
    /// @param  id_       The id of the scheduled transaction to cancel.
    function _proposeCancel(address safe_, address timelock_, address sender_, bytes32 id_) internal {
        bytes memory data_ = _getCancelData(timelock_, id_);

        _safeMultiSig.initialize(safe_);
        _proposeToTimelock(timelock_, data_, sender_, SafeNonce.next(_safeMultiSig));
    }

    /// @notice Proposes to cancel a pending timelock operation at an explicit Safe nonce.
    /// @dev    For when the Safe transaction service cannot be queried or the proposal must queue at a chosen position.
    /// @param  safe_     The address of the Safe multisig to propose the transaction to.
    /// @param  timelock_ The address of the timelock.
    /// @param  sender_   The sender's address.
    /// @param  id_       The id of the scheduled transaction to cancel.
    /// @param  nonce_    The Safe nonce to propose at.
    function _proposeCancel(address safe_, address timelock_, address sender_, bytes32 id_, uint256 nonce_) internal {
        bytes memory data_ = _getCancelData(timelock_, id_);

        _safeMultiSig.initialize(safe_);
        _proposeToTimelock(timelock_, data_, sender_, nonce_);
    }

    /// @dev    Signs and proposes a call to the timelock at `nonce_` through the initialized Safe client.
    /// @param  timelock_ The address of the timelock.
    /// @param  data_     The call data for the timelock.
    /// @param  sender_   The sender's address.
    /// @param  nonce_    The Safe nonce to propose at.
    function _proposeToTimelock(address timelock_, bytes memory data_, address sender_, uint256 nonce_) private {
        console.log("[nonce] proposing at nonce", nonce_);

        bytes memory signature_ = _safeMultiSig.sign(timelock_, data_, Enum.Operation.Call, sender_, nonce_, "");

        _safeMultiSig.proposeTransactionWithSignature(timelock_, data_, sender_, signature_, nonce_);
    }

    /// @dev    Builds the `scheduleBatch` call for the batch, at the timelock's minimum delay.
    /// @param  timelock_    The address of the timelock.
    /// @param  predecessor_ The predecessor transaction, if any.
    /// @param  salt_        The salt to build the transaction with, if any.
    /// @return The call data for the timelock.
    function _getScheduleBatchData(
        address timelock_,
        bytes32 predecessor_,
        bytes32 salt_
    ) private view returns (bytes memory) {
        uint256 delay_ = TimelockController(payable(timelock_)).getMinDelay();

        return _getScheduleBatchCallData(predecessor_, salt_, delay_);
    }

    /// @dev    Builds the `cancel` call for a pending operation.
    /// @param  timelock_ The address of the timelock.
    /// @param  id_       The id of the scheduled transaction to cancel.
    /// @return The call data for the timelock.
    function _getCancelData(address timelock_, bytes32 id_) private view returns (bytes memory) {
        if (!TimelockController(payable(timelock_)).isOperationPending(id_)) revert OperationNotPending(id_);

        return abi.encodeCall(TimelockController.cancel, id_);
    }
}
