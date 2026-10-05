// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { SafeTimelockBatchBase } from "../../script/SafeTimelockBatchBase.sol";

contract TimelockBatchBaseHarness is SafeTimelockBatchBase {
    function addToBatch(address target_, bytes memory payload_) external {
        _addToTimelockBatch(target_, payload_);
    }

    function executeBatch(address target_, bytes32 predecessor_, bytes32 salt_) external {
        _executeTimelockBatch(target_, predecessor_, salt_);
    }

    function getOperationBatchId(address target_, bytes32 predecessor_, bytes32 salt_) external view returns (bytes32) {
        return _getOperationBatchId(target_, predecessor_, salt_);
    }

    function simulateBatch(address timelock_) external {
        _simulateBatch(timelock_);
    }

    function proposeCancel(address safe_, address timelock_, address sender_, bytes32 id_) external {
        _proposeCancel(safe_, timelock_, sender_, id_);
    }
}
