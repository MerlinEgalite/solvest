// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "solmate/test/utils/mocks/MockERC20.sol";
import "./helpers/BaseTest.sol";
import "../src/TransferVest.sol";

contract MockTransferVest is TransferVest {
    constructor(address sender, address token) TransferVest(sender, token) {}
}

contract TransferVestTest is BaseTest {
    MockTransferVest internal vest;
    ERC20 internal token;
    address internal sender = address(0x1);

    function setUp() public {
        token = new MockERC20("Test", "TST", 18);
        deal(address(token), sender, type(uint128).max);

        vest = new MockTransferVest(sender, address(token));

        vm.prank(sender);
        token.approve(address(vest), type(uint256).max);

        vm.warp(TWENTY_YEARS + OFFSET);
    }

    function testTransferVestDeploymentShouldFailWhenAddressIsZero() public {
        vm.expectRevert(Vest.AddressIsZero.selector);
        new MockTransferVest(address(0), address(token));

        vm.expectRevert(Vest.AddressIsZero.selector);
        new MockTransferVest(sender, address(0));
    }

    function testGetSender() public {
        assertEq(vest.getSender(), sender);
    }

    function testGetToken() public {
        assertEq(vest.getToken(), address(token));
    }

    function testClaimAndTranfserTokensAfterCliff(
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
        receiver = _boundAddressNotZero(receiver);
        vm.assume(receiver != sender);
        start = _boundStart(start);
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
