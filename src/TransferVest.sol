// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Vest} from "./Vest.sol";

contract TransferVest is Vest {
    using SafeTransferLib for ERC20;

    /* IMMUTABLES */

    address internal immutable _sender;
    address internal immutable _token;

    /* CONSTRUCTOR */

    constructor(address sender, address token) Vest() {
        if (sender == address(0) || token == address(0)) revert AddressIsZero();
        _sender = sender;
        _token = token;
    }

    /* EXTERNAL */

    function getSender() external view returns (address) {
        return _sender;
    }

    function getToken() external view returns (address) {
        return _token;
    }

    /* INTERNAL */

    function _transfer(address receiver, uint256 amount) internal override {
        ERC20(_token).safeTransferFrom(_sender, receiver, amount);
    }
}
