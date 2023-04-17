// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title IMintable
/// @author MerlinEgalite
/// @notice Smallest interface for a mintable token.
interface IMintable {
    function mint(address to, uint256 amount) external;
}
