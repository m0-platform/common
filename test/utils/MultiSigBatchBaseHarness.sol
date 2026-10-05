// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { MultiSigBatchBase } from "../../script/MultiSigBatchBase.sol";

contract MultiSigBatchBaseHarness is MultiSigBatchBase {
    function addToBatch(address target_, bytes memory data_) external {
        _addToBatch(target_, data_);
    }

    function simulateBatch(address safe_) external {
        _simulateBatch(safe_);
    }
}
