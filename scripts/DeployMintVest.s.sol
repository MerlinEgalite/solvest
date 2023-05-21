pragma solidity 0.8.17;

import "forge-std/Script.sol";

import {MintVest} from "../src/MintVest.sol";

contract DeployMintVest is Script{

    /// @dev Change these values before running the script!
    address public owner = address(0xCAFE);
    address public token = address(0xBEEF); 

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployedInstance = address(new MintVest(owner,token));
        console.log("MintVest contract deployed at: ",deployedInstance, " for the token: ", token);
        vm.stopBroadcast();
    }
}