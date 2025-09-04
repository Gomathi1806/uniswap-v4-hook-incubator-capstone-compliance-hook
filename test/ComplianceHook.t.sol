// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/ComplianceHook.sol";
//import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

contract ComplianceHookTest is Test {
    using PoolIdLibrary for PoolKey;

    ComplianceHook hook;
    //address mockPoolManager = address(0x1234);

    address user1 = address(0x1);
    address user2 = address(0x2);

    PoolKey poolKey;
    PoolId poolId;

    function setUp() public {
        // Deploy hook
        hook = new ComplianceHook();

        // Setup test pool
        poolKey = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
        poolId = poolKey.toId();

        // Setup test users
        hook.setComplianceStatus(user1, true);
        hook.setHumanityScore(user1, 50);
        hook.setRiskScore(user1, 30);
    }

    function test_DeployerIsAuthorized() public {
        assertTrue(hook.authorizedOperators(address(this)));
    }

    function test_ConfigurePoolCompliance() public {
        hook.configurePoolCompliance(poolId, true, 40, 50, false);

        (
            bool requiresCompliance,
            uint256 minHumanity,
            uint256 maxRisk,
            bool requiresKYC
        ) = hook.poolCompliance(poolId);

        assertTrue(requiresCompliance);
        assertEq(minHumanity, 40);
        assertEq(maxRisk, 50);
        assertFalse(requiresKYC);
    }

    function test_UserComplianceCheck() public {
        hook.configurePoolCompliance(poolId, true, 40, 50, false);

        // user1 should be compliant (humanity: 50, risk: 30)
        assertTrue(hook.checkUserCompliance(user1, poolId));

        // user2 should not be compliant (not set up)
        assertFalse(hook.checkUserCompliance(user2, poolId));
    }

    function test_ValidateTransaction() public {
        hook.configurePoolCompliance(poolId, true, 40, 50, false);

        // Should pass for compliant user
        hook.validateTransaction(user1, poolId);

        // Should revert for non-compliant user
        vm.expectRevert(
            abi.encodeWithSelector(
                ComplianceHook.UserNotCompliant.selector,
                user2,
                "User not compliant"
            )
        );
        hook.validateTransaction(user2, poolId);
    }

    function test_SetComplianceData() public {
        hook.setComplianceStatus(user2, true);
        hook.setHumanityScore(user2, 60);
        hook.setRiskScore(user2, 20);

        assertTrue(hook.complianceStatus(user2));
        assertEq(hook.humanityScores(user2), 60);
        assertEq(hook.riskScores(user2), 20);
    }

    function test_NonCompliantPoolAllowsAll() public {
        // Pool without compliance requirements should allow all users
        hook.configurePoolCompliance(poolId, false, 0, 0, false);

        assertTrue(hook.checkUserCompliance(user1, poolId));
        assertTrue(hook.checkUserCompliance(user2, poolId)); // Even non-compliant user
    }

    function test_CreatePoolId() public {
        PoolId testPoolId = hook.createPoolId(
            address(0x1),
            address(0x2),
            3000,
            60,
            address(hook)
        );

        // Should create a valid pool ID
        assertTrue(PoolId.unwrap(testPoolId) != bytes32(0));
    }
}
