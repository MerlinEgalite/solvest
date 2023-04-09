// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

contract BaseTest is Test {
    uint256 internal constant OFFSET = 1_000;
    uint256 internal constant TOTAL = 1_000;
    uint256 internal constant TWENTY_YEARS = 20 * 365 days;
    uint256 internal constant DURATION = 3 * 365 days;

    uint256 internal immutable START;

    constructor() {
        START = block.timestamp + 30 days;
    }
}
