// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../src/interfaces/IVest.sol";

import "solmate/test/utils/mocks/MockERC20.sol";
import "./helpers/BaseTest.sol";
import "../src/MintVest.sol";

contract MockMintVest is MintVest {
    constructor(address token) MintVest(msg.sender, token) {}
}

contract MintVestTest is BaseTest {
    MockMintVest internal vest;
    ERC20 internal token;

    function setUp() public {
        token = new MockERC20("Test", "TST", 18);
        vest = new MockMintVest(address(token));

        vm.warp(TWENTY_YEARS + OFFSET);
    }

    function testMintVestDeploymentShouldFailWhenAddressIsZero() public {
        vm.expectRevert(IVest.AddressIsZero.selector);
        new MockMintVest(address(0));
    }

    function testGetToken() public {
        assertEq(vest.getToken(), address(token));
    }

    function testClaimAndMintTokensAfterCliff(
        address receiver,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total,
        uint256 claimTime
    ) public {
        receiver = _boundAddressNotZero(receiver);
        start = _boundStart(start);
        duration = bound(duration, OFFSET, TWENTY_YEARS);
        cliffDuration = bound(cliffDuration, 0, duration);
        claimTime = bound(claimTime, start + cliffDuration, type(uint128).max);
        total = bound(total, TOTAL, type(uint128).max);

        uint256 id = vest.create(receiver, start, cliffDuration, duration, manager, restricted, protected, total);

        vm.warp(claimTime);

        vm.prank(receiver);
        vest.claim(id);
        uint256 accrued = vest.getAccrued(block.timestamp, start, start + duration, total);

        Vest.Vesting memory vesting = vest.getVesting(id);

        assertEq(vesting.claimed, accrued);
        assertEq(ERC20(token).balanceOf(receiver), accrued);
    }
}
