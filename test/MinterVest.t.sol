// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "solmate/test/utils/mocks/MockERC20.sol";
import "./helpers/BaseTest.sol";
import "../src/MinterVest.sol";

contract MockMinterVest is MinterVest {
    constructor(address token) MinterVest(token) {}
}

contract MinterVestTest is BaseTest {
    MockMinterVest internal vest;
    ERC20 internal token;

    function setUp() public {
        token = new MockERC20("Test", "TST", 18);
        vest = new MockMinterVest(address(token));

        vm.warp(TWENTY_YEARS + OFFSET);
    }

    function testMinterVestDeploymentShouldFailWhenAddressIsZero() public {
        vm.expectRevert(Vest.AddressIsZero.selector);
        new MockMinterVest(address(0));
    }

    function testGetToken() public {
        assertEq(vest.getToken(), address(token));
    }

    function testClaimAndMintTokensAfterCliff(
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total,
        uint256 claimTime
    ) public {
        vm.assume(receiver != address(0));
        start = bound(start, OFFSET, block.timestamp + TWENTY_YEARS);
        duration = bound(duration, OFFSET, TWENTY_YEARS);
        cliff = bound(cliff, 0, duration);
        claimTime = bound(claimTime, start + cliff, type(uint128).max);
        total = bound(total, TOTAL, type(uint128).max);

        uint256 id = vest.create(receiver, start, cliff, duration, manager, restricted, protected, total);

        vm.warp(claimTime);

        vm.prank(receiver);
        vest.claim(id);
        uint256 accrued = vest.getAccrued(block.timestamp, start, start + duration, total);

        Vest.Vesting memory vesting = vest.getVesting(id);

        assertEq(vesting.claimed, accrued);
        assertEq(ERC20(token).balanceOf(receiver), accrued);
    }
}
