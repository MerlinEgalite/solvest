// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IMinter} from "./interfaces/IMinter.sol";

import {Vest} from "./Vest.sol";

/// @title MinterVest
/// @author MerlinEgalite
/// @notice MinterVest contract allowing an owner to create and manage vestings.
/// @dev Claimed tokens are directly minted on the token.
contract MinterVest is Vest {
    /* IMMUTABLES */

    /// @dev The token being vested.
    address internal immutable _token;

    /* CONSTRUCTOR */

    /// @notice Constructs the contract and sets the `token` being vested.
    constructor(address token) Vest() {
        if (token == address(0)) revert AddressIsZero();
        _token = token;
    }

    /* EXTERNAL */

    /// @notice Returns the token being vested.
    function getToken() external view returns (address) {
        return _token;
    }

    /* INTERNAL */

    /// @dev Mints `amount` of tokens to the `receiver`.
    function _transfer(address receiver, uint256 amount) internal override {
        IMinter(_token).mint(receiver, amount);
    }
}
