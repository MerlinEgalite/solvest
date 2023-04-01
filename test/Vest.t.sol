// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "forge-std/StdStorage.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "../src/Vest.sol";

contract MockVest is Vest {
    address internal immutable _token;

    constructor(address token) Vest() {
        _token = token;
    }

    function validateId(uint256 id) external {
        _validateId(id);
    }

    function _transfer(address receiver, uint256 amount) internal override {
        // Manipulate the state.
    }
}

contract VestTest is Test {
    using stdStorage for StdStorage;

    event VestingCreated(uint256 id, address receiver);

    uint256 internal immutable START;
    uint256 internal constant TWENTY_YEARS = 20 * 365 days;
    uint256 internal constant OFFSET = 1000;
    uint256 internal constant DURATION = 3 * 365 days;

    MockVest internal vest;
    ERC20 internal token;

    address alice = address(0x1);
    address bob = address(0x2);

    constructor() {
        START = block.timestamp + 30 days;
    }

    function setUp() public {
        token = new MockERC20("Test", "TST", 18);
        vest = new MockVest(address(token));

        vm.warp(TWENTY_YEARS + OFFSET);
    }

    function testOwner() public {
        assertEq(vest.owner(), address(this));
    }

    function testCreate(
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) public {
        vm.assume(receiver != address(0));
        start = bound(start, OFFSET, block.timestamp + TWENTY_YEARS);
        cliff = bound(cliff, 0, TWENTY_YEARS);
        duration = bound(duration, 1, TWENTY_YEARS);
        total = bound(total, 1, type(uint128).max);

        vm.expectEmit();
        emit VestingCreated(1, receiver);
        uint256 id = vest.create(receiver, start, cliff, duration, manager, restricted, protected, total);

        Vest.Vesting memory vesting = vest.getVesting(id);

        assertEq(id, 1);
        assertEq(vesting.receiver, receiver);
        assertEq(vesting.start, start);
        assertEq(vesting.cliff, start + cliff);
        assertEq(vesting.end, start + duration);
        assertEq(vesting.manager, manager);
        assertEq(vesting.restricted, restricted);
        assertEq(vesting.protected, protected);
        assertEq(vesting.total, total);
        assertEq(vesting.claimed, 0);
    }

    function testCreateShouldRevertWhenCalledByNotOwner(
        address caller,
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) public {
        vm.assume(caller != address(this));
        vm.assume(receiver != address(0));
        start = bound(start, OFFSET, block.timestamp + TWENTY_YEARS);
        cliff = bound(cliff, 0, TWENTY_YEARS);
        duration = bound(duration, 1, TWENTY_YEARS);
        total = bound(total, 1, type(uint128).max);

        vm.prank(caller);
        vm.expectRevert("UNAUTHORIZED");
        vest.create(receiver, start, cliff, duration, manager, restricted, protected, total);
    }

    function testCreateShouldRevertWhenReceiverIsZero(
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) public {
        start = bound(start, OFFSET, block.timestamp + TWENTY_YEARS);
        cliff = bound(cliff, 0, TWENTY_YEARS);
        duration = bound(duration, 1, TWENTY_YEARS);
        total = bound(total, 1, type(uint128).max);

        vm.expectRevert(Vest.AddressIsZero.selector);
        vest.create(address(0), start, cliff, duration, manager, restricted, protected, total);
    }

    function testCreateShouldRevertWhenTotalIsZero(
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected
    ) public {
        vm.assume(receiver != address(0));
        start = bound(start, OFFSET, block.timestamp + TWENTY_YEARS);
        cliff = bound(cliff, 0, TWENTY_YEARS);
        duration = bound(duration, 1, TWENTY_YEARS);

        vm.expectRevert(Vest.TotalIsZero.selector);
        vest.create(receiver, start, cliff, duration, manager, restricted, protected, 0);
    }

    function testCreateShouldRevertWhenStartIsTooFar(
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) public {
        vm.assume(receiver != address(0));
        start = bound(start, block.timestamp + TWENTY_YEARS + OFFSET, type(uint48).max);
        cliff = bound(cliff, 0, TWENTY_YEARS);
        duration = bound(duration, 1, TWENTY_YEARS);
        total = bound(total, 1, type(uint128).max);

        vm.expectRevert(Vest.StartTooFar.selector);
        vest.create(receiver, start, cliff, duration, manager, restricted, protected, total);
    }

    function testCreateShouldRevertWhenStartTooLongAgo(
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) public {
        vm.assume(receiver != address(0));
        start = bound(start, 0, block.timestamp - TWENTY_YEARS - 1);
        cliff = bound(cliff, 0, TWENTY_YEARS);
        duration = bound(duration, 1, TWENTY_YEARS);
        total = bound(total, 1, type(uint128).max);

        vm.expectRevert(Vest.StartTooLongAgo.selector);
        vest.create(receiver, start, cliff, duration, manager, restricted, protected, total);
    }

    function testCreateShouldRevertWhenDurationIsZero(
        address receiver,
        uint256 start,
        uint256 cliff,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) public {
        vm.assume(receiver != address(0));
        start = bound(start, OFFSET, block.timestamp + TWENTY_YEARS);
        cliff = bound(cliff, 0, TWENTY_YEARS);
        total = bound(total, 1, type(uint128).max);

        vm.expectRevert(Vest.DurationIsZero.selector);
        vest.create(receiver, start, cliff, 0, manager, restricted, protected, total);
    }

    function testCreateShouldRevertWhenDurationIsTooLong(
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) public {
        vm.assume(receiver != address(0));
        start = bound(start, OFFSET, block.timestamp + TWENTY_YEARS);
        cliff = bound(cliff, 0, TWENTY_YEARS);
        duration = bound(duration, TWENTY_YEARS + 1, type(uint48).max);
        total = bound(total, 1, type(uint128).max);

        vm.expectRevert(Vest.DurationTooLong.selector);
        vest.create(receiver, start, cliff, duration, manager, restricted, protected, total);
    }

    function testCreateShouldRevertWhenCliffIsTooLong(
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) public {
        vm.assume(receiver != address(0));
        start = bound(start, OFFSET, block.timestamp + TWENTY_YEARS);
        cliff = bound(cliff, TWENTY_YEARS + 1, type(uint48).max);
        duration = bound(duration, 1, TWENTY_YEARS);
        total = bound(total, 1, type(uint128).max);

        vm.expectRevert(Vest.CliffTooLong.selector);
        vest.create(receiver, start, cliff, duration, manager, restricted, protected, total);
    }

    function testValidateId(uint256 ids, uint256 id) public {
        ids = bound(ids, 1, type(uint256).max);
        id = bound(id, 0, ids - 1);
        stdstore.target(address(vest)).sig("ids()").checked_write(ids);

        vest.validateId(id);
    }

    function testValidateIdShouldRevertIfIdStrictlySuperiorToIds(uint256 ids, uint256 id) public {
        ids = bound(ids, 0, type(uint256).max - 1);
        id = bound(id, ids + 1, type(uint256).max);
        stdstore.target(address(vest)).sig("ids()").checked_write(ids);

        vm.expectRevert(Vest.InvalidVestingId.selector);
        vest.validateId(id);
    }

    function _createVest() internal {
        vest.create(alice, START, 0, DURATION, address(0), false, false, 1000);
    }
}
