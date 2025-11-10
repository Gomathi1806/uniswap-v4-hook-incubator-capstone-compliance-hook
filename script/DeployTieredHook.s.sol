// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {TieredComplianceHook} from "../src/TieredComplianceHook.sol";

contract DeployTieredHook is Script {
    address constant POOL_MANAGER = 0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A;
    address constant FEE_COLLECTOR = 0x3d25913BeC5CEF152776A8302dB39A4EA700bc0B;
    
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        console.log("Deployer:", vm.addr(pk));
        vm.startBroadcast(pk);
        TieredComplianceHook hook = new TieredComplianceHook(IPoolManager(POOL_MANAGER), FEE_COLLECTOR);
        console.log("TieredComplianceHook:", address(hook));
        console.log("RiskCalc:", hook.RISK_CALCULATOR());
        console.log("Chainlink:", hook.CHAINLINK_ORACLE());
        console.log("Fhenix:", hook.FHENIX_FHE());
        vm.stopBroadcast();
    }
}
