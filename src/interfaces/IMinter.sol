// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

/// @title IMinter
/// @author MerlinEgalite
/// @notice Smallest interface for a mintable token.
interface IMinter {
    function mint(address to, uint256 amount) external;
}
