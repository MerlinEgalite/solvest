// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IMinter {
    function mint(address to, uint256 amount) external;
}
