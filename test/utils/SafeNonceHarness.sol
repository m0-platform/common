// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { HTTP } from "../../lib/safe-utils/lib/solidity-http/src/HTTP.sol";

import { SafeNonce } from "../../script/SafeNonce.sol";

contract SafeNonceHarness {
    function fromResponse(uint256 onChain_, HTTP.Response memory response_) external pure returns (uint256) {
        return SafeNonce.fromResponse(onChain_, response_);
    }
}
