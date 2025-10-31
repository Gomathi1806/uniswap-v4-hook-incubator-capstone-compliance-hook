// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/UniswapV4FHEComplianceHook.sol";

contract DeployUniswapHook is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Constructor arguments
        address poolManager = 0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A;  // Uniswap V4 PoolManager
        address riskCalculator = 0xC832d3a0a8349aE0b407AFd71F58c41f732137C9;  // Your CrossChainRiskCalculator
        address fhenixCompliance = 0xEae8DE4CFDFdEfe892180F54A8Fa0639F3A7A08e;  // Your FhenixFHECompliance
        address chainlinkOracle = 0x74B92925FE7898875A19aC7cB9a662eF14DAe41A;  // Your ChainlinkComplianceOracle
        
        UniswapV4FHEComplianceHook hook = new UniswapV4FHEComplianceHook(
            IPoolManager(poolManager),
            riskCalculator,
            fhenixCompliance,
            chainlinkOracle
        );
        
        console.log("UniswapV4FHEComplianceHook deployed at:", address(hook));
        console.log("Owner:", hook.owner());
        console.log("PoolManager:", address(hook.poolManager()));
        console.log("RiskCalculator:", address(hook.riskCalculator()));
        console.log("FhenixCompliance:", address(hook.fhenixCompliance()));
        console.log("ChainlinkOracle:", address(hook.chainlinkOracle()));
        
        vm.stopBroadcast();
    }
}
