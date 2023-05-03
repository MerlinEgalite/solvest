pragma solidity 0.8.17;

import "forge-std/Script.sol";

import {TransferVest} from "../src/TransferVest.sol";

contract DeployTransferVest is Script{

    /// @dev Change these values before running the script!
    address public owner = address(0xCAFE);
    address public token = address(0xBEEF); 
    address public sender = address(0xFACE); 

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployedInstance = address(new TransferVest(owner, sender, token));
        console.log("TransferVest contract deployed at: ", deployedInstance, " for the token: ", token);
        vm.stopBroadcast();
    }
}