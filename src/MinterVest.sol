// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IMinterVest} from "./interfaces/IMinterVest.sol";
import {IMinter} from "./interfaces/IMinter.sol";

import {Vest} from "./Vest.sol";

/// @title MinterVest
/// @author MerlinEgalite
/// @notice MinterVest contract allowing an owner to create and manage vestings.
/// @dev Claimed tokens are directly minted on the token.
contract MinterVest is IMinterVest, Vest {
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
