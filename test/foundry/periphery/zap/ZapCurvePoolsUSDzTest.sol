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

import {PegStabilityModule} from "../../../../contracts/core/psm/PegStabilityModule.sol";
import {StakingLPRewards} from "../../../../contracts/periphery/staking/StakingLPRewards.sol";

import {IERC20, MockCurvePool} from "../../../../contracts/mocks/MockCurvePool.sol";
import {ZapCurvePoolsUSDz} from "../../../../contracts/periphery/zaps/ZapCurvePoolsUSDz.sol";
import {BaseZaiTest, console} from "../../base/BaseZaiTest.sol";

contract ZapCurvePoolsUSDzTest is BaseZaiTest {
  StakingLPRewards internal staking;
  ZapCurvePoolsUSDz internal zap;
  PegStabilityModule internal psmUSDC;
  MockCurvePool internal pool;

  string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

  function test_zap_fork() public {
    uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(20_478_389);

    address user = 0x95Ba4cF87D6723ad9C0Db21737D862bE80e93911;
    IERC20 _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 _susdz = IERC20(0x69000E468f7f6d6f4ed00cF46f368ACDAc252553);
    IERC20 _zai = IERC20(0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0);
    IERC20 _pool = IERC20(0x6eE1955afB64146B126162b4fF018db1eb8f08C3);
    IERC20 _staking = IERC20(0xeF12d1614eb0e2bC8E8884c7d4C7f15E34164F40);
    address _psmUSDC = 0x69000052a82e218ccB61FE6E9d7e3F87b9C5916f;

    ZapCurvePoolsUSDz _zap = new ZapCurvePoolsUSDz(
      address(_staking), // lp staking pool
      address(_susdz), // susdz
      _psmUSDC // psm
    );

    vm.startPrank(user);
    _usdc.approve(address(_zap), type(uint256).max);
    _zap.zapIntoLP(100e6, 0);

    vm.stopPrank();

    assertGe(_pool.balanceOf(address(_staking)), 0, "!pool.balanceOf(staking)");
    assertEq(_usdc.balanceOf(_psmUSDC), 253_970_597, "!usdc.balanceOf(psmUSDC)");

    assertEq(_zai.balanceOf(address(_zap)), 0, "!zai.balanceOf(zap)");
    assertEq(_usdc.balanceOf(address(_zap)), 0, "!usdc.balanceOf(zap)");

    assertApproxEqAbs(_staking.balanceOf(user), 100e18, 1e18, "!staking.balanceOf(user)");
  }
}
