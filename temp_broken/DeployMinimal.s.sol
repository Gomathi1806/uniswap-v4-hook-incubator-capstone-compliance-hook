// script/DeployMinimal.s.sol
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MinimalComplianceHook} from "../src/MinimalComplianceHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

contract DeployMinimalScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Minimal Compliance Hook Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Balance:", address(deployer).balance);

        vm.startBroadcast(deployerPrivateKey);

        // Use a placeholder address for testing
        // In production, use actual Uniswap V4 PoolManager
        address poolManagerAddress = 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829; // Sepolia example

        MinimalComplianceHook hook = new MinimalComplianceHook(
            IPoolManager(poolManagerAddress)
        );

        console.log("MinimalComplianceHook deployed at:", address(hook));

        vm.stopBroadcast();
    }
}
