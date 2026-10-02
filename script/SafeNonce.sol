// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { HTTP } from "../lib/safe-utils/lib/solidity-http/src/HTTP.sol";
import { Safe } from "../lib/safe-utils/src/Safe.sol";

import { console } from "../lib/forge-std/src/console.sol";
import { Vm } from "../lib/forge-std/src/Vm.sol";

/// @notice Gets the next free Safe nonce from the Safe transaction service.
/// @dev    The Safe on-chain nonce advances only on execution. Two proposals at one nonce compete,
///         and only one of them can execute.
library SafeNonce {
    using HTTP for *;
    using Safe for *;

    Vm private constant _vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice Thrown if the Safe transaction service does not answer the pending proposals query.
    /// @param statusCode_ The HTTP status code of the response.
    /// @param response_ The body of the response.
    error PendingProposalsQueryFailed(uint256 statusCode_, string response_);

    /// @notice Returns the next free nonce of `safe_`: the on-chain nonce, or one above the highest pending proposal.
    /// @dev    Initializes `client_` for `safe_`. Reverts if the Safe transaction service does not answer.
    function next(Safe.Client storage client_, address safe_) internal returns (uint256 nonce_) {
        client_.initialize(safe_);
        uint256 onChain_ = client_.getNonce();

        HTTP.Response memory response_ = client_
            .instance()
            .http
            .instance()
            .GET(
                string.concat(
                    client_.getApiKitUrl(block.chainid),
                    "/v1/safes/",
                    _vm.toString(safe_),
                    "/multisig-transactions/?executed=false&nonce__gte=",
                    _vm.toString(onChain_),
                    "&ordering=-nonce&limit=1"
                )
            )
            .request();

        if (response_.status < 200 || response_.status >= 300) {
            revert PendingProposalsQueryFailed(response_.status, response_.data);
        }

        uint256 pendingCount_ = _vm.parseJsonUint(response_.data, ".count");
        uint256 highestPending_;

        if (pendingCount_ == 0) {
            console.log("[nonce] Safe nonce %d, no pending proposals", onChain_);
        } else {
            highestPending_ = _vm.parseJsonUint(response_.data, ".results[0].nonce");
            console.log(
                "[nonce] Safe nonce %d, %d pending proposal(s) up to nonce %d",
                onChain_,
                pendingCount_,
                highestPending_
            );
        }

        nonce_ = nextFrom(onChain_, pendingCount_, highestPending_);

        console.log("[nonce] proposing at nonce", nonce_);
    }

    /// @notice Returns `onChain_` if no proposal is pending at or above it, else the highest pending nonce plus one.
    function nextFrom(
        uint256 onChain_,
        uint256 pendingCount_,
        uint256 highestPending_
    ) internal pure returns (uint256) {
        return pendingCount_ == 0 || highestPending_ < onChain_ ? onChain_ : highestPending_ + 1;
    }
}
