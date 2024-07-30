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
import {ZapCurvePool} from "../../../contracts/periphery/zaps/ZapCurvePool.sol";
import {BaseZaiTest, console} from "../base/BaseZaiTest.sol";

contract ZapCurvePoolTest is BaseZaiTest {
  SafetyPool internal safetyPool;
  ZapCurvePool internal zap;
  PegStabilityModule internal psmUSDC;
  MockCurvePool internal pool;

  string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

  function test_zap() public {
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

    // zap = new ZapCurvePool(address(safetyPool), address(psmUSDC));

    // bytes32 role = safetyPool.MANAGER_ROLE();
    // vm.prank(governance);
    // safetyPool.grantRole(role, governance);

    // assertEq(zap.decimalOffset(), 1e12);

    // vm.startPrank(whale);
    // zai.approve(address(safetyPool), type(uint256).max);
    // usdc.mint(whale, 100e6);
    // usdc.approve(address(zap), type(uint256).max);
    // zap.zapIntoLP(100e6, 0);
    // vm.stopPrank();

    // assertEq(zai.balanceOf(address(pool)), 50e18);
    // assertEq(usdc.balanceOf(address(psmUSDC)), 50e6);
    // assertEq(usdc.balanceOf(address(pool)), 50e6);
    // assertEq(zai.balanceOf(address(zap)), 0);
    // assertEq(usdc.balanceOf(address(zap)), 0);
    // assertApproxEqAbs(safetyPool.balanceOf(whale), 50e18, 1e17);
  }

  function test_zap_fork() public {
    uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(20_419_140);

    address user = 0x95Ba4cF87D6723ad9C0Db21737D862bE80e93911;
    IERC20 _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 _zai = IERC20(0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0);
    IERC20 _pool = IERC20(0x057c658DfBBcbb96C361Fb4e66B86cCA081B6C6A);
    IERC20 _staking = IERC20(0x0Aad7FC97a30670714957e91276C2296d3b7e9D0);
    address _psmUSDC = 0x69000052a82e218ccB61FE6E9d7e3F87b9C5916f;

    ZapCurvePool _zap = new ZapCurvePool(
      address(_staking), // lp staking pool
      _psmUSDC, // psm
      0x08780fb7E580e492c1935bEe4fA5920b94AA95Da // router
    );

    vm.startPrank(user);
    _usdc.approve(address(_zap), type(uint256).max);
    _zap.zapIntoLP(100e6, 0);

    vm.stopPrank();

    assertGe(_pool.balanceOf(address(_staking)), 0, "!pool.balanceOf(staking)");
    assertEq(_usdc.balanceOf(_psmUSDC), 109_030_000, "!usdc.balanceOf(psmUSDC)");

    assertEq(_zai.balanceOf(address(_zap)), 0, "!zai.balanceOf(zap)");
    assertEq(_usdc.balanceOf(address(_zap)), 0, "!usdc.balanceOf(zap)");

    assertApproxEqAbs(_staking.balanceOf(user), 100e18, 1e18, "!staking.balanceOf(user)");
  }
}
