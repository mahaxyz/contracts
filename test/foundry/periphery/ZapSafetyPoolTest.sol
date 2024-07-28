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

import {PegStabilityModule} from "../../../contracts/core/psm/PegStabilityModule.sol";
import {SafetyPool} from "../../../contracts/core/safety-pool/SafetyPool.sol";

import {ZapSafetyPool} from "../../../contracts/periphery/zaps/ZapSafetyPool.sol";
import {BaseZaiTest, console} from "../base/BaseZaiTest.sol";

contract ZapSafetyPoolTest is BaseZaiTest {
  SafetyPool internal safetyPool;
  ZapSafetyPool internal zap;
  PegStabilityModule internal psmUSDC;

  function setUp() public {
    _setUpBase();
    zai.mint(whale, 1000 ether);

    safetyPool = new SafetyPool();
    safetyPool.initialize(
      "Safety Pool", "sZAI", address(zai), 10 days, governance, address(usdc), address(maha), 7 days, address(0)
    );

    psmUSDC = new PegStabilityModule();
    psmUSDC.initialize(
      address(zai), // address _zai,
      address(usdc), // address _collateral,
      governance, // address _governance,
      1e6, // uint256 _newRate,
      100_000 * 1e6, // uint256 _supplyCap,
      100_000 * 1e18, // uint256 _debtCap
      0, // supplyFeeBps 1%
      100, // redeemFeeBps 1%
      feeDestination
    );

    zai.grantManagerRole(address(psmUSDC));

    zap = new ZapSafetyPool(address(safetyPool), address(zai));

    bytes32 role = safetyPool.MANAGER_ROLE();
    vm.prank(governance);
    safetyPool.grantRole(role, governance);

    vm.prank(whale);
    zai.approve(address(safetyPool), type(uint256).max);
  }

  function test_zap() public {
    vm.startPrank(whale);
    usdc.mint(whale, 100e6);

    usdc.approve(address(zap), type(uint256).max);
    zap.zapIntoSafetyPool(psmUSDC, 100e6);

    vm.stopPrank();

    assertEq(zai.balanceOf(address(safetyPool)), 100e18);
    assertEq(usdc.balanceOf(address(psmUSDC)), 100e6);

    assertEq(zai.balanceOf(address(zap)), 0);
    assertEq(usdc.balanceOf(address(zap)), 0);

    assertEq(safetyPool.balanceOf(whale), 100e18);
  }
}
