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

import {ZaiStablecoin} from "../../contracts/core/ZaiStablecoin.sol";
import {PegStabilityModule} from "../../contracts/core/psm/PegStabilityModule.sol";
import {BaseZaiTest} from "./base/BaseZaiTest.t.sol";

contract PegStabilityModuleTest is BaseZaiTest {
  PegStabilityModule public psmUSDC;
  PegStabilityModule public psmDAI;

  function setUp() public {
    _setUpBase();

    psmUSDC = new PegStabilityModule();
    psmUSDC.initialize(
      address(zai), // address _zai,
      address(usdc), // address _collateral,
      governance, // address _governance,
      1e8, // uint256 _newRate,
      100_000 * 1e8, // uint256 _supplyCap,
      100_000 * 1e18, // uint256 _debtCap
      100, // supplyFeeBps 1%
      100, // redeemFeeBps 1%
      feeDestination
    );

    psmDAI = new PegStabilityModule();
    psmDAI.initialize(
      address(zai), // address _zai,
      address(dai), // address _collateral,
      governance, // address _governance,
      1e18, // uint256 _newRate,
      100_000 * 1e18, // uint256 _supplyCap,
      100_000 * 1e18, // uint256 _debtCap
      100, // supplyFeeBps 1%
      100, // redeemFeeBps 1%
      feeDestination
    );

    // give permissions
    zai.grantManagerRole(address(psmUSDC));
    zai.grantManagerRole(address(psmDAI));
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
    usdc.mint(ant, 2000 * 1e8);

    assertEq(zai.totalSupply(), 0);

    usdc.approve(address(psmUSDC), 2000 * 1e8);
    psmUSDC.mint(ant, 1000 ether);

    assertEq(zai.totalSupply(), 1000 ether);
    assertEq(zai.balanceOf(ant), 1000 ether);
    assertEq(usdc.balanceOf(address(psmUSDC)), 1010 * 1e8);
    vm.stopPrank();

    vm.expectRevert();
    psmUSDC.mint(ant, 1000 ether);
  }

  function test_redeemPartial() public {
    vm.startPrank(ant);
    usdc.mint(ant, 2000 * 1e8);
    usdc.approve(address(psmUSDC), 2000 * 1e8);
    psmUSDC.mint(ant, 1000 ether);
    zai.transfer(whale, 500 ether);
    vm.stopPrank();

    assertEq(zai.totalSupply(), 1000 ether);
    assertEq(usdc.balanceOf(address(psmUSDC)), 1010 * 1e8);
    assertEq(zai.balanceOf(whale), 500 ether);

    // as whale try to redeem
    vm.startPrank(whale);
    zai.approve(address(psmUSDC), 500 ether);
    psmUSDC.redeem(whale, 300 ether);

    // check balances
    assertEq(zai.totalSupply(), 700 ether);
    assertEq(usdc.balanceOf(address(psmUSDC)), 713 * 1e8);
    assertEq(zai.balanceOf(whale), 200 ether);

    vm.expectRevert();
    psmUSDC.redeem(whale, 300 ether);
  }

  function test_redeemFull() public {
    vm.startPrank(ant);
    usdc.mint(ant, 2000 * 1e8);
    usdc.approve(address(psmUSDC), 2000 * 1e8);
    psmUSDC.mint(ant, 1000 ether);

    assertEq(zai.totalSupply(), 1000 ether);
    assertEq(usdc.balanceOf(address(psmUSDC)), 1010 * 1e8);
    assertEq(zai.balanceOf(ant), 1000 ether);

    zai.approve(address(psmUSDC), 1000 ether);
    psmUSDC.redeem(ant, 1000 ether);

    // check balances
    assertEq(zai.totalSupply(), 0);
    assertEq(usdc.balanceOf(address(psmUSDC)), 20 * 1e8);
    assertEq(zai.balanceOf(ant), 0);

    vm.expectRevert();
    psmUSDC.redeem(ant, 300 ether);
  }

  function test_sweepFees() public {
    vm.startPrank(ant);
    usdc.mint(ant, 2000 * 1e8);
    usdc.approve(address(psmUSDC), 2000 * 1e8);
    zai.approve(address(psmUSDC), 1000 ether);
    psmUSDC.mint(ant, 1000 ether);

    psmUSDC.redeem(ant, 1000 ether);

    // check balances
    assertEq(zai.totalSupply(), 0);
    assertEq(usdc.balanceOf(address(psmUSDC)), 20 * 1e8);
    assertEq(zai.balanceOf(ant), 0);

    psmUSDC.sweepFees();

    assertEq(usdc.balanceOf(address(feeDestination)), 20 * 1e8);
  }
}
