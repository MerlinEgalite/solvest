// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IMinter} from "./interfaces/IMinter.sol";

import {Vest} from "./Vest.sol";

contract MinterVest is Vest {
    /* IMMUTABLES */

    address internal immutable _token;

    /* CONSTRUCTOR */

    constructor(address token) Vest() {
        if (token == address(0)) revert AddressIsZero();
        _token = token;
    }

    /* EXTERNAL */

    function geToken() external view returns (address) {
        return _token;
    }

    /* INTERNAL */

    function _transfer(address receiver, uint256 amount) internal override {
        IMinter(_token).mint(receiver, amount);
    }
}
