// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IVest {
    /* STRUCTS */

    struct Vesting {
        address receiver; // The receiver of the vesting.
        uint48 start; // The start time of the vesting.
        uint48 cliff; // The end of the cliff.
        uint48 end; // The end of the vesting.
        address manager; // The manager of the vesting that can claim the tokens if the vesting is not restricted.
        bool restricted; // True if the manager cannot claim tokens on behalf of receiver.
        bool protected; // True if the vesting cannot be revoked.
        uint128 total; // The total amount of vested tokens.
        uint128 claimed; // The amount of tokens already claimed.
    }

    /* ERRORS */

    /// @notice Thrown when the sender has not the permission to call the function.
    error PermissionDenied();

    /// @notice Thrown when only the receiver can call the function.
    error OnlyReceiver();

    /// @notice Thrown when the address passed as argument is the zero address.
    error AddressIsZero();

    /// @notice Thrown when the total amount of tokens is zero for a new vesting.
    error TotalIsZero();

    /// @notice Thrown when the start time is too far in the future for a new vesting.
    error StartTooFar();

    /// @notice Thrown when the start time is too far in the past for a new vesting.
    error StartTooLongAgo();

    /// @notice Thrown when the duration is zero for a new vesting.
    error DurationIsZero();

    /// @notice Thrown when the duration is too long for a new vesting.
    error DurationTooLong();

    /// @notice Thrown when the cliff duration is too long for a new vesting.
    error CliffDurationTooLong();

    /// @notice Thrown when the vesting does not exist.
    error InvalidVestingId();

    /// @notice Thrown when the vesting is not revokable.
    error VestingIsProtected();

    /* EVENTS */

    /// @notice Emitted when a vesting is created with `id` and `receiver`.
    event VestingCreated(uint256 id, address receiver);

    /// @notice Emitted when the vesting `id` is revoked at `end`.
    event VestingRevoked(uint256 id, uint256 end);

    /// @notice Emitted when an `amount` of tokens is claimed for the vesting `id`.
    event Claimed(uint256 id, uint256 amount);

    /// @notice Emitted when the vesting `id` is protected.
    event VestingProtected(uint256 id);

    /// @notice Emitted when the vesting `id` is unprotected.
    event VestingUnprotected(uint256 id);

    /// @notice Emitted when the vesting `id` is restricted.
    event VestingRestricted(uint256 id);

    /// @notice Emitted when the vesting `id` is unrestricted.
    event VestingUnrestricted(uint256 id);

    /// @notice Emitted when the receiver of vesting `id` is set to `receiver`.
    event ReceiverSet(uint256 id, address receiver);

    /* GETTERS */

    function TWENTY_YEARS() external pure returns (uint256);
    function ids() external view returns (uint256);
    function getVesting(uint256 id) external view returns (Vesting memory);
    function getUnclaimed(uint256 id) external view returns (uint256);

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
    ) external returns (uint256 id);
    function revoke(uint256 id) external;
    function revoke(uint256 id, uint256 end) external;
    function claim(uint256 id) external;
    function protect(uint256 id) external;
    function unprotect(uint256 id) external;
    function restrict(uint256 id) external;
    function unrestrict(uint256 id) external;
    function setReceiver(uint256 id, address receiver) external;
}
