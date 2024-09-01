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
import {ZapCurvePoolUSDC} from "../../../../contracts/periphery/zaps/implementations/ethereum/ZapCurvePoolUSDC.sol";
import {BaseZaiTest, console} from "../../base/BaseZaiTest.sol";

contract ZapCurvePoolUSDCTest is BaseZaiTest {
  StakingLPRewards public staking;
  ZapCurvePoolUSDC public zap;
  PegStabilityModule public psmUSDC;
  MockCurvePool public pool;

  string public MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

  function test_zap_fork() public {
    uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(20_478_389);

    address user = 0x95Ba4cF87D6723ad9C0Db21737D862bE80e93911;
    IERC20 _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 _zai = IERC20(0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0);
    IERC20 _pool = IERC20(0x6eE1955afB64146B126162b4fF018db1eb8f08C3);
    IERC20 _staking = IERC20(0x154F52B347D8E48b8DbD8D8325Fe5bb45AAdCCDa);
    address _psmUSDC = 0x69000052a82e218ccB61FE6E9d7e3F87b9C5916f;

    ZapCurvePoolUSDC _zap = new ZapCurvePoolUSDC(
      address(_staking), // lp staking pool
      _psmUSDC // psm
    );

    vm.startPrank(user);
    _usdc.approve(address(_zap), type(uint256).max);
    _zap.zapIntoLP(100e6, 0);

    vm.stopPrank();

    //  74960013339750528199
    // 100000000000000000000

    assertGe(_pool.balanceOf(address(_staking)), 0, "!pool.balanceOf(staking)");
    assertEq(_usdc.balanceOf(_psmUSDC), 203_970_597, "!usdc.balanceOf(psmUSDC)");

    assertEq(_zai.balanceOf(address(_zap)), 0, "!zai.balanceOf(zap)");
    assertEq(_usdc.balanceOf(address(_zap)), 0, "!usdc.balanceOf(zap)");

    assertApproxEqAbs(_staking.balanceOf(user), 100e18, 1e18, "!staking.balanceOf(user)");
  }
}
