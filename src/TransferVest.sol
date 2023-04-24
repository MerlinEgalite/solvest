// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITransferVest} from "./interfaces/ITransferVest.sol";

import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Vest} from "./Vest.sol";

/// @title TransferVest
/// @author MerlinEgalite
/// @notice TransferVest contract allowing an owner to create and manage vestings.
/// @dev Claimed tokens are directly transferred from a sender to the receivers.
contract TransferVest is ITransferVest, Vest {
    using SafeTransferLib for ERC20;

    /* IMMUTABLES */

    /// @dev The sender of the tokens.
    address internal immutable _sender;

    /// @dev The token being vested.
    address internal immutable _token;

    /* CONSTRUCTOR */

    /// @notice Constructs the contract.
    /// @param owner The owner of the contract.
    /// @param sender The sender of the vested token.
    /// @param token The token being vested.
    constructor(address owner, address sender, address token) Vest(owner) {
        if (sender == address(0) || token == address(0)) revert AddressIsZero();
        _sender = sender;
        _token = token;
    }

    /* EXTERNAL */

    /// @notice Returns the sender of the tokens.
    function getSender() external view returns (address) {
        return _sender;
    }

    /// @notice Returns the token being vested.
    function getToken() external view returns (address) {
        return _token;
    }

    /* INTERNAL */

    /// @dev Transfers `amount` of tokens from the `sender` to the `receiver`.
    function _transfer(address receiver, uint256 amount) internal override {
        ERC20(_token).safeTransferFrom(_sender, receiver, amount);
    }
}
