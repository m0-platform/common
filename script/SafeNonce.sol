// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { HTTP } from "../lib/safe-utils/lib/solidity-http/src/HTTP.sol";
import { Safe } from "../lib/safe-utils/src/Safe.sol";

import { console } from "../lib/forge-std/src/console.sol";
import { Vm } from "../lib/forge-std/src/Vm.sol";

/// @title  Next free Safe nonce, read from the Safe transaction service.
/// @author M0 Labs
library SafeNonce {
    using HTTP for *;
    using Safe for *;

    Vm private constant _vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice Thrown if the Safe transaction service does not answer the pending proposals query.
    /// @param  statusCode_ The HTTP status code of the response.
    /// @param  response_   The body of the response.
    error PendingProposalsQueryFailed(uint256 statusCode_, string response_);

    /// @notice Returns the next free nonce of the Safe `client_` is initialized for.
    /// @dev    Reverts if the Safe transaction service does not answer. The propose helpers accept an explicit
    ///         nonce to bypass the service.
    /// @param  client_ The Safe client, initialized for the Safe.
    /// @return The on-chain nonce, or one above the highest pending proposal.
    function next(Safe.Client storage client_) internal returns (uint256) {
        uint256 onChain_ = client_.getNonce();

        HTTP.Response memory response_ = client_
            .instance()
            .http
            .instance()
            .GET(_getPendingProposalsUrl(client_, onChain_))
            .request();

        uint256 nonce_ = fromResponse(onChain_, response_);

        console.log("[nonce] Safe on-chain nonce %d, next free nonce %d", onChain_, nonce_);

        return nonce_;
    }

    /// @notice Returns the next free nonce from a page of pending proposals at or above `onChain_`.
    /// @dev    Reverts if `response_` is not a 2xx answer.
    /// @param  onChain_  The Safe's on-chain nonce.
    /// @param  response_ The transaction service page of pending proposals, highest nonce first.
    /// @return `onChain_` if no proposal is pending at or above it, else the highest pending nonce plus one.
    function fromResponse(uint256 onChain_, HTTP.Response memory response_) internal pure returns (uint256) {
        if (response_.status < 200 || response_.status >= 300) {
            revert PendingProposalsQueryFailed(response_.status, response_.data);
        }

        if (_vm.parseJsonUint(response_.data, ".count") == 0) return onChain_;

        uint256 next_ = _vm.parseJsonUint(response_.data, ".results[0].nonce") + 1;

        // NOTE: A service that ignores `nonce__gte` can return a stale proposal below the on-chain nonce, e.g. the
        //       loser of a past collision. Never propose below the on-chain nonce.
        return next_ > onChain_ ? next_ : onChain_;
    }

    /// @dev    Builds the transaction service query for the pending proposals at or above `onChain_`.
    /// @param  client_  The Safe client, initialized for the Safe.
    /// @param  onChain_ The Safe's on-chain nonce.
    /// @return The URL, ordered by nonce descending and limited to the first result.
    function _getPendingProposalsUrl(
        Safe.Client storage client_,
        uint256 onChain_
    ) private view returns (string memory) {
        return
            string.concat(
                client_.getApiKitUrl(block.chainid),
                "/v1/safes/",
                _vm.toString(client_.instance().safe),
                "/multisig-transactions/?executed=false&nonce__gte=",
                _vm.toString(onChain_),
                "&ordering=-nonce&limit=1"
            );
    }
}
