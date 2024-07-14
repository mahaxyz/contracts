// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {ZaiStablecoin} from "../contracts/core/ZaiStablecoin.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract PegStabilityModuleTest is BaseTest {
    function setUp() public {
        setUpBase();
    }

    function test_values() public view {
        assertEq(address(psmUSDC.zai()), address(zai), "!psm");
        assertEq(psmUSDC.supplyCap(), 100_000 * 1e8, "!supplyCap");
        assertEq(psmUSDC.debtCap(), 100_000 ether, "!debtCap");
        assertEq(psmUSDC.debt(), 0, "!debt");
    }

    function test_toCollateralAmount() public view {
        assertEq(psmUSDC.toCollateralAmount(1000 ether), 1000 * 1e8, "!usdc");
        assertEq(psmDAI.toCollateralAmount(1000 ether), 1000 ether, "!dai");
    }

    function test_mint() public {
        vm.startPrank(ant);
        usdc.mint(ant, 1000 * 1e8);

        assertEq(zai.totalSupply(), 0);

        usdc.approve(address(psmUSDC), 1000 * 1e8);
        psmUSDC.mint(ant, 1000 ether);

        assertEq(zai.totalSupply(), 1000 ether);
        assertEq(zai.balanceOf(ant), 1000 ether);
        assertEq(usdc.balanceOf(address(psmUSDC)), 1000 * 1e8);
        vm.stopPrank();

        vm.expectRevert();
        psmUSDC.mint(ant, 1000 ether);
    }

    function test_redeem() public {
        vm.startPrank(ant);
        usdc.mint(ant, 1000 * 1e8);
        usdc.approve(address(psmUSDC), 1000 * 1e8);
        psmUSDC.mint(ant, 1000 ether);
        zai.transfer(whale, 500 ether);
        vm.stopPrank();

        assertEq(zai.totalSupply(), 1000 ether);
        assertEq(usdc.balanceOf(address(psmUSDC)), 1000 * 1e8);
        assertEq(zai.balanceOf(whale), 500 ether);

        // as whale try to redeem
        vm.startPrank(whale);
        zai.approve(address(psmUSDC), 500 ether);
        psmUSDC.redeem(whale, 300 ether);

        // check balances
        assertEq(zai.totalSupply(), 700 ether);
        assertEq(usdc.balanceOf(address(psmUSDC)), 700 * 1e8);
        assertEq(zai.balanceOf(whale), 200 ether);

        vm.expectRevert();
        psmUSDC.redeem(whale, 300 ether);
    }
}
