// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ComplianceHook.sol"; // Use your working contract

contract SimpleDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Simple Compliance Hook...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // Deploy your working compliance hook
        ComplianceHook hook = new ComplianceHook();

        console.log("Compliance Hook deployed to:", address(hook));

        vm.stopBroadcast();
    }
}
