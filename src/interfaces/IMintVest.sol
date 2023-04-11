// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

import {IVest} from "./IVest.sol";

/// @title IMintVest
/// @author MerlinEgalite
/// @notice Interface that the MintVest contract must implement.
interface IMintVest is IVest {
    function getToken() external view returns (address);
}
