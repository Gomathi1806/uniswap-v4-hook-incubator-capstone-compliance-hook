pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/BasicHook.sol";

contract DeployBasicScript is Script {
    function run() external {
        vm.startBroadcast();
        
        BasicHook hook = new BasicHook();
        console.log("BasicHook deployed at:", address(hook));
        
        vm.stopBroadcast();
    }
}
