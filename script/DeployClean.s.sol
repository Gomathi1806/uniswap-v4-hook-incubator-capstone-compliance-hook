pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CleanCompliance.sol";

contract DeployCleanScript is Script {
    function run() external {
        vm.startBroadcast();
        
        CleanCompliance hook = new CleanCompliance();
        console.log("CleanCompliance deployed at:", address(hook));
        
        vm.stopBroadcast();
    }
}
