// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/UniswapV4FHEComplianceHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract DeployHook is Script {
    function run() external {
        vm.startBroadcast();
        
        new UniswapV4FHEComplianceHook(
            IPoolManager(0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A),
            0xC832d3a0a8349aE0b407AFd71F58c41f732137C9,
            0xEae8DE4CFDFdEfe892180F54A8Fa0639F3A7A08e,
            0x74B92925FE7898875A19aC7cB9a662eF14DAe41A
        );
        
        vm.stopBroadcast();
    }
}
