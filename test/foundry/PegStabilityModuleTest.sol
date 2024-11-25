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

pragma solidity 0.8.21;

import {BasePsmTest} from "./base/BasePsmTest.sol";

contract PegStabilityModuleTest is BasePsmTest {
  function setUp() public {
    _setUpPSM();
  }

  function test_values() public view {
    assertEq(address(psmUSDC.zai()), address(zai), "!psm");
    assertEq(psmUSDC.supplyCap(), 100_000 * 1e6, "!supplyCap");
    assertEq(psmUSDC.debtCap(), 100_000 ether, "!debtCap");
    assertEq(psmUSDC.debt(), 0, "!debt");
  }

  function test_toCollateralAmount() public view {
    assertEq(psmUSDC.toCollateralAmount(1000 ether), 1000 * 1e6, "!usdc");
    assertEq(psmDAI.toCollateralAmount(1000 ether), 1000 ether, "!dai");
  }

  function test_mint() public {
    vm.startPrank(ant);
    usdc.mint(ant, 2000 * 1e6);

    assertEq(zai.totalSupply(), 0);

    usdc.approve(address(psmUSDC), 2000 * 1e6);
    psmUSDC.mint(ant, 1000 ether);

    assertEq(zai.totalSupply(), 1000 ether);
    assertEq(zai.balanceOf(ant), 1000 ether);
    assertEq(usdc.balanceOf(address(psmUSDC)), 1010 * 1e6);
    vm.stopPrank();

    vm.expectRevert();
    psmUSDC.mint(ant, 1000 ether);
  }

  function test_redeemPartial() public {
    vm.startPrank(ant);
    usdc.mint(ant, 2000 * 1e6);
    usdc.approve(address(psmUSDC), 2000 * 1e6);
    psmUSDC.mint(ant, 1000 ether);
    zai.transfer(whale, 500 ether);
    vm.stopPrank();

    assertEq(zai.totalSupply(), 1000 ether);
    assertEq(usdc.balanceOf(address(psmUSDC)), 1010 * 1e6);
    assertEq(zai.balanceOf(whale), 500 ether);

    // as whale try to redeem
    vm.startPrank(whale);
    zai.approve(address(psmUSDC), 500 ether);
    psmUSDC.redeem(whale, 300 ether);

    // check balances
    assertEq(zai.totalSupply(), 700 ether);
    assertEq(usdc.balanceOf(address(psmUSDC)), 713 * 1e6);
    assertEq(zai.balanceOf(whale), 200 ether);

    vm.expectRevert();
    psmUSDC.redeem(whale, 300 ether);
  }

  function test_redeemFull() public {
    vm.startPrank(ant);
    usdc.mint(ant, 2000 * 1e6);
    usdc.approve(address(psmUSDC), 2000 * 1e6);
    psmUSDC.mint(ant, 1000 ether);

    assertEq(zai.totalSupply(), 1000 ether);
    assertEq(usdc.balanceOf(address(psmUSDC)), 1010 * 1e6);
    assertEq(zai.balanceOf(ant), 1000 ether);

    zai.approve(address(psmUSDC), 1000 ether);
    psmUSDC.redeem(ant, 1000 ether);

    // check balances
    assertEq(zai.totalSupply(), 0);
    assertEq(usdc.balanceOf(address(psmUSDC)), 20 * 1e6);
    assertEq(zai.balanceOf(ant), 0);

    vm.expectRevert();
    psmUSDC.redeem(ant, 300 ether);
  }

  // function test_sweepFees() public {
  //   vm.startPrank(ant);
  //   usdc.mint(ant, 2000 * 1e6);
  //   usdc.approve(address(psmUSDC), 2000 * 1e6);
  //   zai.approve(address(psmUSDC), 1000 ether);
  //   psmUSDC.mint(ant, 1000 ether);

  //   psmUSDC.redeem(ant, 1000 ether);

  //   // check balances
  //   assertEq(zai.totalSupply(), 0);
  //   assertEq(usdc.balanceOf(address(psmUSDC)), 20 * 1e6);
  //   assertEq(zai.balanceOf(ant), 0);

  //   psmUSDC.sweepFees();

  //   assertEq(usdc.balanceOf(address(feeDestination)), 20 * 1e6);
  // }
}
