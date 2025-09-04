// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/SimpleCompliance.sol";

contract SimpleComplianceTest is Test {
    SimpleCompliance compliance;
    address user1 = address(0x1);

    function setUp() public {
        compliance = new SimpleCompliance();
    }

    function test_OwnerIsCompliant() public {
        assertTrue(compliance.isCompliant(address(this)));
    }

    function test_SetCompliance() public {
        compliance.setCompliance(user1, true);
        assertTrue(compliance.checkCompliance(user1));
    }

    function test_OnlyOwnerCanSetCompliance() public {
        vm.prank(user1);
        vm.expectRevert("Only owner");
        compliance.setCompliance(user1, true);
    }
}
