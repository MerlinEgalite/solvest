// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

abstract contract Vest is Owned {
    using SafeCastLib for uint256;

    /* ERRORS */

    error PermissionDenied();
    error OnlyReceiver();
    error AddressIsZero();
    error TotalIsZero();
    error StartTooFar();
    error StartTooLongAgo();
    error DurationIsZero();
    error DurationTooLong();
    error CliffTooLong();
    error InvalidVestingId();

    /* EVENTS */

    event VestingCreated(uint256 id, address receiver);
    event VestingRevoked(uint256 id, uint256 end);
    event Claimed(uint256 id, uint256 amount);
    event VestingProtected(uint256 id);
    event VestingUnprotected(uint256 id);
    event VestingRestricted(uint256 id);
    event VestingUnrestricted(uint256 id);
    event ReceiverSet(uint256 id, address receiver);

    /* STRCUTS */

    struct Vesting {
        address receiver;
        uint48 start;
        uint48 cliff;
        uint48 end;
        address manager;
        bool restricted;
        bool protected;
        uint128 total;
        uint128 claimed;
    }

    /* CONSTANTS */

    uint256 internal constant _TWENTY_YEARS = 20 * 365 days;

    /* STORAGE */

    uint256 internal _ids;
    mapping(uint256 => Vesting) internal _vestings;

    /* CONSTRUCTOR */

    constructor() Owned(msg.sender) {}

    /* GETTERS */

    function TWENTY_YEARS() external pure returns (uint256) {
        return _TWENTY_YEARS;
    }

    function ids() external view returns (uint256) {
        return _ids;
    }

    function getVesting(uint256 id) external view returns (Vesting memory) {
        return _vestings[id];
    }

    function getUnclaimed(uint256 id) external view returns (uint256) {
        return _unclaimed(id);
    }

    function getAccrued(uint256 time, uint256 start, uint256 end, uint256 total) external pure returns (uint256) {
        return _accrued(time, start, end, total);
    }

    /* EXTERNAL */

    function create(
        address receiver,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        address manager,
        bool restricted,
        bool protected,
        uint256 total
    ) external onlyOwner returns (uint256 id) {
        if (receiver == address(0)) revert AddressIsZero();
        if (total == 0) revert TotalIsZero();
        if (start > block.timestamp + _TWENTY_YEARS) revert StartTooFar();
        if (start < block.timestamp - _TWENTY_YEARS) revert StartTooLongAgo();
        if (duration == 0) revert DurationIsZero();
        if (duration > _TWENTY_YEARS) revert DurationTooLong();
        if (cliff > duration) revert CliffTooLong();

        id = ++_ids;
        _vestings[id] = Vesting({
            receiver: receiver,
            start: uint48(start), // No need to safe cast since start <= block.timestamp + _TWENTY_YEARS which fits in a uint48.
            cliff: uint48(start + cliff), // No need to safe cast since cliff <= duration which fits in a uint48.
            end: uint48(start + duration), // No need to safe cast since duration <= _TWENTY_YEARS which fits in a uint48.
            manager: manager,
            restricted: restricted,
            protected: protected,
            total: total.safeCastTo128(),
            claimed: 0
        });

        emit VestingCreated(id, receiver);
    }

    function revoke(uint256 id) external onlyOwner {
        _revoke(id, block.timestamp);
    }

    function revoke(uint256 id, uint256 end) external onlyOwner {
        _revoke(id, end);
    }

    function claim(uint256 id) external {
        Vesting storage vesting = _vestings[id];
        if (msg.sender != vesting.receiver && (vesting.restricted || msg.sender != vesting.manager)) {
            revert PermissionDenied();
        }
        uint256 amount = _unclaimed(id);
        vesting.claimed += amount.safeCastTo128();
        _transfer(vesting.receiver, amount);
        emit Claimed(id, amount);
    }

    function protect(uint256 id) external onlyOwner {
        _validateId(id);
        _vestings[id].protected = true;
        emit VestingProtected(id);
    }

    function unprotect(uint256 id) external onlyOwner {
        _validateId(id);
        _vestings[id].protected = false;
        emit VestingUnprotected(id);
    }

    function restrict(uint256 id) external {
        _validateId(id);
        if (msg.sender != _vestings[id].receiver && msg.sender != owner) revert PermissionDenied();
        _vestings[id].restricted = true;
        emit VestingRestricted(id);
    }

    function unrestrict(uint256 id) external {
        _validateId(id);
        if (msg.sender != _vestings[id].receiver && msg.sender != owner) revert PermissionDenied();
        _vestings[id].restricted = false;
        emit VestingUnrestricted(id);
    }

    function setReceiver(uint256 id, address receiver) external {
        if (msg.sender != _vestings[id].receiver) revert OnlyReceiver();
        if (receiver == address(0)) revert AddressIsZero();
        _vestings[id].receiver = receiver;
        emit ReceiverSet(id, receiver);
    }

    /* INTERNAL */

    function _validateId(uint256 id) internal view {
        if (id > _ids) revert InvalidVestingId();
    }

    function _unclaimed(uint256 id) internal view returns (uint256) {
        Vesting storage vesting = _vestings[id];
        uint256 accrued =
            block.timestamp < vesting.cliff ? 0 : _accrued(block.timestamp, vesting.start, vesting.end, vesting.total);
        return accrued - vesting.claimed;
    }

    function _accrued(uint256 time, uint256 start, uint256 end, uint256 total) internal pure returns (uint256) {
        if (time < start) return 0;
        if (time >= end) return total;
        uint256 delta = time - start;
        return (total * delta) / (end - start);
    }

    function _revoke(uint256 id, uint256 end) internal {
        Vesting storage vesting = _vestings[id];
        if (end < block.timestamp) end = block.timestamp;

        if (end < vesting.end) {
            uint48 castedEnd = end.safeCastTo48();
            vesting.end = castedEnd;

            if (castedEnd < vesting.start) {
                vesting.start = castedEnd;
                vesting.cliff = castedEnd;
                vesting.total = 0;
            } else if (castedEnd < vesting.cliff) {
                vesting.cliff = castedEnd;
                vesting.total = 0;
            } else {
                vesting.total = _accrued(end, vesting.start, vesting.end, vesting.total).safeCastTo128();
            }
        }
    }

    function _transfer(address receiver, uint256 amount) internal virtual;
}
