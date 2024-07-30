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

  function test_zap_fork() public {
    uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(20_419_466);

    address user = 0x95Ba4cF87D6723ad9C0Db21737D862bE80e93911;
    IERC20 _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 _zai = IERC20(0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0);
    IERC20 _pool = IERC20(0x057c658DfBBcbb96C361Fb4e66B86cCA081B6C6A);
    IERC20 _staking = IERC20(0x6900066D9F8DF0bfaF1E25Ef89c0453e8e12373d);
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
    assertEq(_usdc.balanceOf(_psmUSDC), 114_030_000, "!usdc.balanceOf(psmUSDC)");

    assertEq(_zai.balanceOf(address(_zap)), 0, "!zai.balanceOf(zap)");
    assertEq(_usdc.balanceOf(address(_zap)), 0, "!usdc.balanceOf(zap)");

    assertApproxEqAbs(_staking.balanceOf(user), 100e18, 1e18, "!staking.balanceOf(user)");
  }
}
