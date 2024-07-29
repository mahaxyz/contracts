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

import {IERC20, MockCurvePool} from "../../../contracts/mocks/MockCurvePool.sol";
import {ZapCuvePool} from "../../../contracts/periphery/zaps/ZapCuvePool.sol";
import {BaseZaiTest, console} from "../base/BaseZaiTest.sol";

contract ZapCuvePoolTest is BaseZaiTest {
  SafetyPool internal safetyPool;
  ZapCuvePool internal zap;
  PegStabilityModule internal psmUSDC;
  MockCurvePool internal pool;

  function setUp() public {
    _setUpBase();
    zai.mint(whale, 1000 ether);

    IERC20[] memory tokens = new IERC20[](2);
    tokens[0] = zai;
    tokens[1] = usdc;
    pool = new MockCurvePool("Curve Pool", "cZAI", tokens);

    safetyPool = new SafetyPool();
    safetyPool.initialize(
      "Staked ZAI/USDC LP",
      "sUSDCZAI-LP",
      address(pool),
      10 days,
      governance,
      address(usdc), // rewards are USDC and MAHA
      address(maha),
      7 days,
      address(0)
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

    zap = new ZapCuvePool(address(safetyPool), address(psmUSDC));

    bytes32 role = safetyPool.MANAGER_ROLE();
    vm.prank(governance);
    safetyPool.grantRole(role, governance);

    vm.prank(whale);
    zai.approve(address(safetyPool), type(uint256).max);

    assertEq(zap.decimalOffset(), 1e12);
  }

  function test_zap() public {
    vm.startPrank(whale);
    usdc.mint(whale, 100e6);

    usdc.approve(address(zap), type(uint256).max);
    zap.zapIntoLP(100e6, 0);

    vm.stopPrank();

    assertEq(zai.balanceOf(address(pool)), 50e18);
    assertEq(usdc.balanceOf(address(psmUSDC)), 50e6);
    assertEq(usdc.balanceOf(address(pool)), 50e6);
    assertEq(zai.balanceOf(address(zap)), 0);
    assertEq(usdc.balanceOf(address(zap)), 0);
    assertApproxEqAbs(safetyPool.balanceOf(whale), 50e18, 1e17);
  }
}
