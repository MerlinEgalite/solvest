// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IVest} from "./interfaces/IVest.sol";

import {Owned} from "solmate/auth/Owned.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

/// @title Vest
/// @author MerlinEgalite
/// @notice Abstract contract allowing an owner to create and manage vestings.
/// @dev Modified and improved version of https://github.com/makerdao/dss-vest.
abstract contract Vest is IVest, Owned {
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
    error CliffDurationTooLong();
    error InvalidVestingId();
    error VestingIsProtected();

    /* EVENTS */

    event VestingCreated(uint256 id, address receiver);
    event VestingRevoked(uint256 id, uint256 end);
    event Claimed(uint256 id, uint256 amount);
    event VestingProtected(uint256 id);
    event VestingUnprotected(uint256 id);
    event VestingRestricted(uint256 id);
    event VestingUnrestricted(uint256 id);
    event ReceiverSet(uint256 id, address receiver);

    /* CONSTANTS */

    /// @dev 20 years in seconds.
    uint256 internal constant _TWENTY_YEARS = 20 * 365 days;

    /* STORAGE */

    /// @dev The total number of created vestings.
    uint256 internal _ids;

    /// @dev Maps an id to a vesting configuration.
    mapping(uint256 => Vesting) internal _vestings;

    /* CONSTRUCTOR */

    /// @notice Constructs the contract and sets `msg.sender` as owner.
    constructor() Owned(msg.sender) {}

    /* GETTERS */

    /// @notice Returns the number of seconds in 20 years.
    function TWENTY_YEARS() external pure returns (uint256) {
        return _TWENTY_YEARS;
    }

    /// @notice Returns the number of created vestings.
    function ids() external view returns (uint256) {
        return _ids;
    }

    /// @notice Returns the vesting data of the vesting `id`.
    function getVesting(uint256 id) external view returns (Vesting memory) {
        return _vestings[id];
    }

    /// @notice Returns the available unclaimed tokens of the vesting `id`.
    function getUnclaimed(uint256 id) external view returns (uint256) {
        return _unclaimed(id);
    }

    /// @dev Returns the amount of token accrued given the different parameters.
    /// @param time The time at which the accrual ends.
    /// @param start The start of the vesting.
    /// @param start The end of the vesting.
    /// @param start The total token amount of the vesting.
    function getAccrued(uint256 time, uint256 start, uint256 end, uint256 total) external pure returns (uint256) {
        return _accrued(time, start, end, total);
    }

    /* EXTERNAL */

    /// @notice Creates a new vesting.
    /// @param receiver The receiver of the vesting.
    /// @param start The start time of the vesting.
    /// @param cliffDuration The cliff duration of the vesting.
    /// @param duration The total duration of the vesting.
    /// @param manager The manager of the vesting that can claim the tokens if the vesting is not restricted, and revoke the vesting if the vesting is not protected.
    /// @param restricted True if the manager cannot claim tokens on behalf of receiver.
    /// @param protected True if the vesting cannot be revoked.
    /// @param total The total amount of vested tokens.
    function create(
        address receiver,
        uint256 start,
        uint256 cliffDuration,
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
        if (cliffDuration > duration) revert CliffDurationTooLong();

        id = ++_ids;
        _vestings[id] = Vesting({
            receiver: receiver,
            start: uint48(start), // No need to safe cast since start <= block.timestamp + _TWENTY_YEARS which fits in a uint48.
            cliff: uint48(start + cliffDuration), // No need to safe cast since cliffDuration <= duration which fits in a uint48.
            end: uint48(start + duration), // No need to safe cast since duration <= _TWENTY_YEARS which fits in a uint48.
            manager: manager,
            restricted: restricted,
            protected: protected,
            total: total.safeCastTo128(),
            claimed: 0
        });

        emit VestingCreated(id, receiver);
    }

    /// @notice Revokes the vesting `id` at `block.timestamp` time.
    /// @dev Callable if the vesting is not protected.
    function revoke(uint256 id) external {
        _revoke(id, block.timestamp);
    }

    /// @notice Revokes the vesting `id` at `end` time.
    /// @dev Callable if the vesting is not protected.
    function revoke(uint256 id, uint256 end) external {
        _revoke(id, end);
    }

    /// @notice Claims the available tokens of the vesting `id` and sends them to the receiver.
    /// @dev Callable by the receiver or the manager if set and the vesting is not restricted.
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

    /// @notice Protects vesting `id` to be revoked.
    function protect(uint256 id) external onlyOwner {
        _validateId(id);
        _vestings[id].protected = true;
        emit VestingProtected(id);
    }

    /// @notice Unprotects vesting `id` to be revoked.
    function unprotect(uint256 id) external onlyOwner {
        _validateId(id);
        _vestings[id].protected = false;
        emit VestingUnprotected(id);
    }

    /// @notice Restricts the vesting `id` to be claimed by the receiver of the vesting only.
    /// @dev Callable by the receiver of the vesting or the owner only.
    function restrict(uint256 id) external {
        _validateId(id);
        Vesting storage vesting = _vestings[id];
        if (msg.sender != vesting.receiver && msg.sender != owner) revert PermissionDenied();
        vesting.restricted = true;
        emit VestingRestricted(id);
    }

    /// @notice Unrestricts the vesting `id` to be claimed by the receiver and the manager if set.
    /// @dev Callable by the receiver of the vesting or the owner only.
    function unrestrict(uint256 id) external {
        _validateId(id);
        Vesting storage vesting = _vestings[id];
        if (msg.sender != vesting.receiver && msg.sender != owner) revert PermissionDenied();
        vesting.restricted = false;
        emit VestingUnrestricted(id);
    }

    /// @notice Sets a new `receiver` to the vesting `id`.
    /// @dev Callable by the receiver of the vesting only.
    function setReceiver(uint256 id, address receiver) external {
        if (receiver == address(0)) revert AddressIsZero();
        Vesting storage vesting = _vestings[id];
        if (msg.sender != vesting.receiver) revert OnlyReceiver();
        vesting.receiver = receiver;
        emit ReceiverSet(id, receiver);
    }

    /* INTERNAL */

    /// @dev Validates that the `id` is correct.
    function _validateId(uint256 id) internal view {
        if (id > _ids) revert InvalidVestingId();
    }

    /// @dev Returns the unclaimed amount of tokens related to the vesting `id`.
    function _unclaimed(uint256 id) internal view returns (uint256) {
        Vesting storage vesting = _vestings[id];
        uint256 accrued =
            block.timestamp < vesting.cliff ? 0 : _accrued(block.timestamp, vesting.start, vesting.end, vesting.total);
        return accrued - vesting.claimed;
    }

    /// @dev Returns the amount of token accrued given the different parameters.
    /// @param time The time at which the accrual ends.
    /// @param start The start of the vesting.
    /// @param start The end of the vesting.
    /// @param start The total token amount of the vesting.
    function _accrued(uint256 time, uint256 start, uint256 end, uint256 total) internal pure returns (uint256) {
        if (time < start) return 0;
        if (time >= end) return total;
        uint256 delta = time - start;
        return (total * delta) / (end - start);
    }

    /// @dev Revokes a vesting if it is not protected.
    /// @dev The new `end` cannot be earlier than the current `block.timestamp`.
    /// @param id The id of the vesting.
    /// @param end The new end of the vesting.
    function _revoke(uint256 id, uint256 end) internal {
        _validateId(id);
        Vesting storage vesting = _vestings[id];
        if (msg.sender != owner && (vesting.protected || msg.sender != vesting.manager)) {
            revert PermissionDenied();
        }

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

            emit VestingRevoked(id, end);
        }
    }

    /// @dev Transfers the `amount` of tokens to `receiver`.
    /// @dev Must be overriden to implement the logic.
    function _transfer(address receiver, uint256 amount) internal virtual;
}
