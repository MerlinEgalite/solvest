// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import {IVest} from "./IVest.sol";

/// @title ITransferVest
/// @author MerlinEgalite
/// @notice Interface that the TransferVest contract must implement.
interface ITransferVest is IVest {
    function getSender() external view returns (address);
    function getToken() external view returns (address);
}
