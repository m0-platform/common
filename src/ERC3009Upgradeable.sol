// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.20 <0.9.0;

import { IERC3009 } from "./interfaces/IERC3009.sol";

import { StatefulERC712Upgradeable } from "./StatefulERC712Upgradeable.sol";

abstract contract ERC3009UpgradeableStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.ERC3009
    struct ERC3009StorageStruct {
        mapping(address authorizer => mapping(bytes32 nonce => bool isNonceUsed)) authorizationState;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.ERC3009")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _ERC3009_STORAGE_LOCATION =
        0x1116a1d33aa5fb91b2652b3b0fdb63704173742d6dbecaf4256ebe33a4888600;

    function _getERC3009StorageLocation() internal pure returns (ERC3009StorageStruct storage $) {
        assembly {
            $.slot := _ERC3009_STORAGE_LOCATION
        }
    }
}

/**
 * @title  ERC3009 implementation allowing the transfer of fungible assets via a signed authorization.
 * @author M0 Labs
 * @dev    Inherits from ERC712ExtendedUpgradeable and StatefulERC712Upgradeable.
 */
abstract contract ERC3009Upgradeable is IERC3009, ERC3009UpgradeableStorageLayout, StatefulERC712Upgradeable {
    /* ============ Variables ============ */

    // solhint-disable-next-line max-line-length
    /// @dev        keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    /// @inheritdoc IERC3009
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    // solhint-disable-next-line max-line-length
    /// @dev        keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    /// @inheritdoc IERC3009
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    /**
     * @inheritdoc IERC3009
     * @dev        keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
     */
    bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH =
        0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the ERC3009Upgradeable contract.
     * @param  name_ The name of the contract.
     */
    function __ERC3009Upgradeable_init(string memory name_) internal onlyInitializing {
        __StatefulERC712ExtendedUpgradeable_init(name_);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IERC3009
    function transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        bytes memory signature_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getTransferWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            signature_
        );

        _transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        bytes32 r_,
        bytes32 vs_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getTransferWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            r_,
            vs_
        );

        _transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getTransferWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            v_,
            r_,
            s_
        );

        _transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        bytes memory signature_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getReceiveWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            signature_
        );

        _receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        bytes32 r_,
        bytes32 vs_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getReceiveWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            r_,
            vs_
        );

        _receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getReceiveWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            v_,
            r_,
            s_
        );

        _receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function cancelAuthorization(address authorizer_, bytes32 nonce_, bytes memory signature_) external {
        _revertIfInvalidSignature(authorizer_, _getCancelAuthorizationDigest(authorizer_, nonce_), signature_);
        _cancelAuthorization(authorizer_, nonce_);
    }

    /// @inheritdoc IERC3009
    function cancelAuthorization(address authorizer_, bytes32 nonce_, bytes32 r_, bytes32 vs_) external {
        _revertIfInvalidSignature(authorizer_, _getCancelAuthorizationDigest(authorizer_, nonce_), r_, vs_);
        _cancelAuthorization(authorizer_, nonce_);
    }

    /// @inheritdoc IERC3009
    function cancelAuthorization(address authorizer_, bytes32 nonce_, uint8 v_, bytes32 r_, bytes32 s_) external {
        _revertIfInvalidSignature(authorizer_, _getCancelAuthorizationDigest(authorizer_, nonce_), v_, r_, s_);
        _cancelAuthorization(authorizer_, nonce_);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC3009
    function authorizationState(address authorizer, bytes32 nonce) public view returns (bool) {
        return _getERC3009StorageLocation().authorizationState[authorizer][nonce];
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Common transfer function used by `transferWithAuthorization` and `_receiveWithAuthorization`.
     * @param from_        Payer's address (Authorizer).
     * @param to_          Payee's address.
     * @param value_       Amount to be transferred.
     * @param validAfter_  The time after which this is valid (unix time).
     * @param validBefore_ The time before which this is valid (unix time).
     * @param nonce_       Unique nonce.
     */
    function _transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) internal {
        if (block.timestamp <= validAfter_) revert AuthorizationNotYetValid(block.timestamp, validAfter_);
        if (block.timestamp >= validBefore_) revert AuthorizationExpired(block.timestamp, validBefore_);

        _revertIfAuthorizationAlreadyUsed(from_, nonce_);

        _getERC3009StorageLocation().authorizationState[from_][nonce_] = true;

        emit AuthorizationUsed(from_, nonce_);

        _transfer(from_, to_, value_);
    }

    /**
     * @dev   Common receive function used by `receiveWithAuthorization`.
     * @param from_        Payer's address (Authorizer).
     * @param to_          Payee's address.
     * @param value_       Amount to be transferred.
     * @param validAfter_  The time after which this is valid (unix time).
     * @param validBefore_ The time before which this is valid (unix time).
     * @param nonce_       Unique nonce.
     */
    function _receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) internal {
        if (msg.sender != to_) revert CallerMustBePayee(msg.sender, to_);

        _transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /**
     * @dev   Common cancel function used by `cancelAuthorization`.
     * @param authorizer_ Authorizer's address.
     * @param nonce_      Nonce of the authorization.
     */
    function _cancelAuthorization(address authorizer_, bytes32 nonce_) internal {
        _revertIfAuthorizationAlreadyUsed(authorizer_, nonce_);

        _getERC3009StorageLocation().authorizationState[authorizer_][nonce_] = true;

        emit AuthorizationCanceled(authorizer_, nonce_);
    }

    /**
     * @dev   Internal ERC20 transfer function that needs to be implemented by the inheriting contract.
     * @param sender_    The sender's address.
     * @param recipient_ The recipient's address.
     * @param amount_    The amount to be transferred.
     */
    function _transfer(address sender_, address recipient_, uint256 amount_) internal virtual;

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns the internal EIP-712 digest of a transferWithAuthorization call.
     * @param  from_        Payer's address (Authorizer).
     * @param  to_          Payee's address.
     * @param  value_       Amount to be transferred.
     * @param  validAfter_  The time after which this is valid (unix time).
     * @param  validBefore_ The time before which this is valid (unix time).
     * @param  nonce_       Unique nonce.
     * @return The internal EIP-712 digest.
     */
    function _getTransferWithAuthorizationDigest(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) internal view returns (bytes32) {
        return
            _getDigest(
                keccak256(
                    abi.encode(
                        TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
                        from_,
                        to_,
                        value_,
                        validAfter_,
                        validBefore_,
                        nonce_
                    )
                )
            );
    }

    /**
     * @dev    Returns the internal EIP-712 digest of a receiveWithAuthorization call.
     * @param  from_        Payer's address (Authorizer).
     * @param  to_          Payee's address.
     * @param  value_       Amount to be transferred.
     * @param  validAfter_  The time after which this is valid (unix time).
     * @param  validBefore_ The time before which this is valid (unix time).
     * @param  nonce_       Unique nonce.
     * @return The internal EIP-712 digest.
     */
    function _getReceiveWithAuthorizationDigest(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) internal view returns (bytes32) {
        return
            _getDigest(
                keccak256(
                    abi.encode(
                        RECEIVE_WITH_AUTHORIZATION_TYPEHASH,
                        from_,
                        to_,
                        value_,
                        validAfter_,
                        validBefore_,
                        nonce_
                    )
                )
            );
    }

    /**
     * @dev    Returns the internal EIP-712 digest of a cancelAuthorization call.
     * @param  authorizer_ Authorizer's address.
     * @param  nonce_      Nonce of the authorization.
     * @return The internal EIP-712 digest.
     */
    function _getCancelAuthorizationDigest(address authorizer_, bytes32 nonce_) internal view returns (bytes32) {
        return _getDigest(keccak256(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, authorizer_, nonce_)));
    }

    /**
     * @dev   Reverts if the authorization is already used.
     * @param authorizer_ The authorizer's address.
     * @param nonce_      The nonce of the authorization.
     */
    function _revertIfAuthorizationAlreadyUsed(address authorizer_, bytes32 nonce_) internal view {
        if (authorizationState(authorizer_, nonce_)) revert AuthorizationAlreadyUsed(authorizer_, nonce_);
    }
}
