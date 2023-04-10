// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

import {IVest} from "./IVest.sol";

/// @title IMinterVest
/// @author MerlinEgalite
/// @notice Interface that the MinterVest contract must implement.
interface IMinterVest is IVest {
    function getToken() external view returns (address);
}
