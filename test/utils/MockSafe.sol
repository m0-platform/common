// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Enum } from "../../lib/safe-utils/lib/safe-smart-account/contracts/common/Enum.sol";

contract MockSafe {
    uint256 public nonce;

    address[] internal _owners;

    constructor(address[] memory owners_) {
        _owners = owners_;
    }

    function execTransaction(
        address,
        uint256,
        bytes calldata,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory
    ) external payable returns (bool) {
        nonce++;
        return true;
    }

    function getOwners() external view returns (address[] memory) {
        return _owners;
    }

    function isOwner(address account_) external view returns (bool) {
        for (uint256 i; i < _owners.length; ++i) {
            if (_owners[i] == account_) return true;
        }

        return false;
    }

    function getThreshold() external pure returns (uint256) {
        return 1;
    }

    function getTransactionHash(
        address to_,
        uint256 value_,
        bytes calldata data_,
        Enum.Operation operation_,
        uint256,
        uint256,
        uint256,
        address,
        address,
        uint256 nonce_
    ) external pure returns (bytes32) {
        return keccak256(abi.encode(to_, value_, data_, operation_, nonce_));
    }
}
