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
import {ZapCurvePoolMAHA} from "../../../../contracts/periphery/zaps/ZapCurvePoolMAHA.sol";
import {BaseZaiTest, console} from "../../base/BaseZaiTest.sol";

contract ZapCurvePoolMAHATest is BaseZaiTest {
  StakingLPRewards internal staking;
  ZapCurvePoolMAHA internal zap;
  PegStabilityModule internal psmUSDC;
  MockCurvePool internal pool;

  string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

  function test_zap_fork() public {
    uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(20_558_099);

    address user = 0x95Ba4cF87D6723ad9C0Db21737D862bE80e93911;
    IERC20 _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 _zai = IERC20(0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0);
    IERC20 _maha = IERC20(0x745407c86DF8DB893011912d3aB28e68B62E49B0);
    IERC20 _pool = IERC20(0x0086Ef314a313018c70A2CD92504c7D1038A25aa);
    IERC20 _staking = IERC20(0x237efE587f2cB44597063DC8403a4892a60A5a4f);
    address _psmUSDC = 0x69000052a82e218ccB61FE6E9d7e3F87b9C5916f;

    ZapCurvePoolMAHA _zap = new ZapCurvePoolMAHA(
      address(_staking), // lp staking pool
      _maha,
      _psmUSDC, // psm
      address(0) // odos
    );

    vm.startPrank(user);
    _usdc.approve(address(_zap), type(uint256).max);
    _zap.zapIntoLP(100e6, 0);

    vm.stopPrank();

    assertGe(_pool.balanceOf(address(_staking)), 0, "!pool.balanceOf(staking)");
    assertEq(_usdc.balanceOf(_psmUSDC), 83_913_990_938, "!usdc.balanceOf(psmUSDC)");

    assertEq(_zai.balanceOf(address(_zap)), 0, "!zai.balanceOf(zap)");
    assertEq(_usdc.balanceOf(address(_zap)), 0, "!usdc.balanceOf(zap)");

    assertApproxEqAbs(_staking.balanceOf(user), 45e18, 1e18, "!staking.balanceOf(user)");
  }
}
