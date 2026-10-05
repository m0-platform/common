// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { SafeNonce } from "./SafeNonce.sol";

import { Enum } from "../lib/safe-utils/lib/safe-smart-account/contracts/common/Enum.sol";
import { OwnerManager } from "../lib/safe-utils/lib/safe-smart-account/contracts/base/OwnerManager.sol";
import { Safe } from "../lib/safe-utils/src/Safe.sol";

import { console } from "../lib/forge-std/src/console.sol";
import { Script } from "../lib/forge-std/src/Script.sol";

abstract contract MultiSigBatchBase is Script {
    using Safe for *;

    Safe.Client internal _safeMultiSig;
    address[] internal _targets;
    bytes[] internal _data;

    function _addToBatch(address target_, bytes memory data_) internal {
        _targets.push(target_);
        _data.push(data_);
    }

    /// @dev    Proposes the batch at the next free Safe nonce. See {SafeNonce-next}.
    /// @param  safe_   The Safe to propose to.
    /// @param  sender_ The owner signing the proposal.
    function _proposeBatch(address safe_, address sender_) internal {
        _safeMultiSig.initialize(safe_);
        _propose(sender_, SafeNonce.next(_safeMultiSig));
    }

    /// @dev    Proposes the batch at an explicit nonce, for when the Safe transaction service cannot be queried or
    ///         the batch must queue at a chosen position.
    /// @param  safe_   The Safe to propose to.
    /// @param  sender_ The owner signing the proposal.
    /// @param  nonce_  The Safe nonce to propose at.
    function _proposeBatch(address safe_, address sender_, uint256 nonce_) internal {
        _safeMultiSig.initialize(safe_);
        _propose(sender_, nonce_);
    }

    /// @dev    Simulates the batch through the Safe itself, using synthetic owner approvals, so that the MultiSend
    ///         encoding, the threshold check and any guard or fallback handler are exercised too.
    /// @param  safe_ The Safe to simulate through.
    function _simulateBatch(address safe_) internal {
        _safeMultiSig.initialize(safe_);

        address[] memory owners_ = OwnerManager(safe_).getOwners();

        uint256 snapshot_ = vm.snapshotState();

        // NOTE: `isolate` mode runs each top-level call as its own transaction, requiring the signer to pay for gas.
        for (uint256 i = 0; i < owners_.length; i++) {
            vm.deal(owners_[i], owners_[i].balance + 1 ether);
        }

        bool success_ = _safeMultiSig.simulateTransactionsMultiSigNoSign(_targets, _data, owners_);

        // NOTE: The simulation executes the batch for real on the local fork, which advances the Safe nonce and
        //       applies the batch. Restoring the state keeps the nonce the proposal is later signed at correct.
        vm.revertToState(snapshot_);

        require(success_, "Simulation failed");
    }

    /// @dev    Signs and proposes the batch at `nonce_` through the initialized Safe client.
    /// @param  sender_ The owner signing the proposal.
    /// @param  nonce_  The Safe nonce to propose at.
    function _propose(address sender_, uint256 nonce_) private {
        console.log("[nonce] proposing at nonce", nonce_);

        (address to_, bytes memory data_) = _safeMultiSig.getProposeTransactionsTargetAndData(_targets, _data);

        // NOTE: Batches are executed via DelegateCall to preserve `msg.sender` across the sub-calls, and the signed
        //       operation must match the proposed one.
        bytes memory signature_ = _safeMultiSig.sign(to_, data_, Enum.Operation.DelegateCall, sender_, nonce_, "");

        _safeMultiSig.proposeTransactionsWithSignature(_targets, _data, sender_, signature_, nonce_);
    }
}
