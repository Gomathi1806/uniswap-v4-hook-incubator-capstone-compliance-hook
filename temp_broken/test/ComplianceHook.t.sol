// test/ComplianceHook.t.sol
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ComplianceHook} from "../src/ComplianceHook.sol";
import {MockWorldID} from "./mocks/MockWorldID.sol";
import {MockComplianceRegistry} from "./mocks/MockComplianceRegistry.sol";

contract ComplianceHookTest is Test {
    ComplianceHook hook;
    MockWorldID worldID;
    MockComplianceRegistry registry;

    address user = address(0x123);
    uint256 nullifierHash = 0x456;

    function setUp() public {
        worldID = new MockWorldID();
        registry = new MockComplianceRegistry();
        hook = new ComplianceHook(
            IPoolManager(address(0)), // Mock pool manager
            worldID,
            registry
        );
    }

    function testWorldIDVerification() public {
        // Test World ID verification flow
        vm.prank(user);
        hook.verifyWorldID(
            0, // root
            0, // signalHash
            nullifierHash,
            0, // externalNullifierHash
            [uint256(0), 0, 0, 0, 0, 0, 0, 0] // proof
        );

        (bool isVerified, uint256 storedNullifier, ) = hook
            .getUserWorldIDStatus(user);
        assertTrue(isVerified);
        assertEq(storedNullifier, nullifierHash);
    }

    function testComplianceCheck() public {
        // Setup user verification
        vm.prank(user);
        hook.verifyWorldID(
            0,
            0,
            nullifierHash,
            0,
            [uint256(0), 0, 0, 0, 0, 0, 0, 0]
        );

        // Setup compliance data
        registry.setComplianceData(nullifierHash, 50, 4, false); // Good compliance

        // Check compliance
        assertTrue(hook.isUserCompliant(user));
    }

    function testSwapBlocking() public {
        // Test that unverified users cannot swap
        vm.expectRevert(ComplianceHook.UserNotWorldIDVerified.selector);
        hook.beforeSwap(
            user,
            PoolKey(
                Currency.wrap(address(0)),
                Currency.wrap(address(0)),
                3000,
                60,
                hook
            ),
            IPoolManager.SwapParams(false, 1000, 0),
            ""
        );
    }
}
