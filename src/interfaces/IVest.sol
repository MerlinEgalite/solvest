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
