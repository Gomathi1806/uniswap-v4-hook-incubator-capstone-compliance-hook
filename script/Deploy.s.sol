// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ComplianceHook.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying ComplianceHook to Sepolia...");
        console.log("Deployer address:", vm.addr(deployerPrivateKey));
        console.log(
            "Deployer balance:",
            address(vm.addr(deployerPrivateKey)).balance
        );

        // Deploy only the working contract
        ComplianceHook hook = new ComplianceHook();

        console.log("ComplianceHook deployed to:", address(hook));
        console.log("Deployment successful!");

        vm.stopBroadcast();
    }
}
