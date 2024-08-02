// SPDX-License-Identifier: GPL-3.0

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../../contracts/core/direct-deposit/plans/DDOperatorPlan.sol";
import "../../../contracts/interfaces/core/IDDPlan.sol";

contract DDOperatorPlanTest is Test {
    DDOperatorPlan public ddOperatorPlan;
    address public admin = address(0x1);
    address public operator = address(0x2);
    address public other = address(0x3);

    function setUp() public {
        ddOperatorPlan = new DDOperatorPlan(1 days, admin);
        vm.startPrank(admin);
        ddOperatorPlan.grantRole(ddOperatorPlan.OPERATOR_ROLE(), operator);
        vm.stopPrank();

        assertEq(ddOperatorPlan.enabled(), 0);
    }

    function testSetTargetAssets() public {
        assertEq(ddOperatorPlan.targetAssets(), 0);
        
        vm.startPrank(operator);
        ddOperatorPlan.setTargetAssets(1000);
        assertEq(ddOperatorPlan.targetAssets(), 1000);
        vm.stopPrank();

        vm.expectRevert();
        ddOperatorPlan.setTargetAssets(1000);
    }

    function testEnablePlan() public {
        vm.prank(operator);
        ddOperatorPlan.enable();

        assertEq(ddOperatorPlan.enabled(), 1);
        assertTrue(ddOperatorPlan.active());
    }

    function testDisablePlan() public {
        vm.prank(operator);
        ddOperatorPlan.disable();

        assertEq(ddOperatorPlan.enabled(), 0);
        assertFalse(ddOperatorPlan.active());
    }

    function testDisablePlanRevertsIfNotAdminOrOperator() public {
        vm.expectRevert("!role");
        ddOperatorPlan.disable();
    }

    function testEnablePlanAsAdmin() public {
        vm.prank(admin);
        ddOperatorPlan.enable();

        assertEq(ddOperatorPlan.enabled(), 1);
        assertTrue(ddOperatorPlan.active());
    }

    function testDisablePlanAsAdmin() public {
        vm.prank(admin);
        ddOperatorPlan.disable();

        assertEq(ddOperatorPlan.enabled(), 0);
        assertFalse(ddOperatorPlan.active());
    }

    function testGetTargetAssetsWhenDisabled() public {
        assertEq(ddOperatorPlan.getTargetAssets(0), 0);
    }

    function testGetTargetAssetsWhenEnabled() public {
        vm.prank(operator);
        ddOperatorPlan.enable();
        assertEq(ddOperatorPlan.getTargetAssets(0), 0);

        vm.prank(operator);
        ddOperatorPlan.setTargetAssets(1000);
        assertEq(ddOperatorPlan.getTargetAssets(0), 1000);
    }

    function testSetTargetAssetsRevertsIfNotOperator() public {
        vm.prank(other);
        vm.expectRevert();
        ddOperatorPlan.setTargetAssets(1000);
    }

    function testGetTargetAssetsEnabledState() public {
        vm.prank(operator);
        ddOperatorPlan.enable();
        assertEq(ddOperatorPlan.getTargetAssets(0), 0);

        vm.prank(operator);
        ddOperatorPlan.setTargetAssets(500);
        assertEq(ddOperatorPlan.getTargetAssets(0), 500);
    }

    function testEnableAsNonOperator() public {
        vm.prank(other);
        vm.expectRevert();
        ddOperatorPlan.enable();
    }

    function testDisableAsNonOperator() public {
        vm.prank(other);
        vm.expectRevert();
        ddOperatorPlan.disable();
    }
}
