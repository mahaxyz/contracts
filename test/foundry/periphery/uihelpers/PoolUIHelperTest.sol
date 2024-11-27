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

import {IERC20, PoolUIHelper} from "../../../../contracts/periphery/ui-helpers/PoolUIHelper.sol";
import {BaseZaiTest, console} from "../../base/BaseZaiTest.sol";

contract PoolUIHelperTest is BaseZaiTest {
  StakingLPRewards internal staking;

  string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

  function test_zap_fork_usdc() public {
    uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(20_483_051);

    IERC20 _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 _zai = IERC20(0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0);
    IERC20 _maha = IERC20(0x745407c86DF8DB893011912d3aB28e68B62E49B0);

    // USDC/ZAI staking
    IERC20 _staking = IERC20(0x154F52B347D8E48b8DbD8D8325Fe5bb45AAdCCDa);

    address user = 0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b;
    address usdcWhale = 0x95Ba4cF87D6723ad9C0Db21737D862bE80e93911;

    PoolUIHelper helper = new PoolUIHelper(
      address(_maha), // maha
      address(_zai), // zai
      address(_zai), // zai
      address(_usdc) // usdc
    );

    vm.prank(0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC);
    StakingLPRewards(address(_staking)).grantRole(keccak256("DISTRIBUTOR_ROLE"), usdcWhale);

    vm.startPrank(usdcWhale);
    _usdc.approve(address(_staking), type(uint256).max);
    StakingLPRewards(address(_staking)).notifyRewardAmount(_usdc, 100e6);

    PoolUIHelper.PoolInfoResponse memory res = helper.getPoolInfo(address(_staking), 91 * 1e6, user); // 0.91$ per maha

    assertEq(res.usdcTotalSupply, 15 * 1e6, "!usdcTotalSupply");
    assertEq(res.zaiTotalSupply, 15 * 1e18, "!zaiTotalSupply");
    assertEq(res.poolUsdTVLE8, 30 * 1e8, "!poolUsdTVL");
    assertApproxEqAbs(res.usdcRewardsPerYearE6, 52 * 100e6, 5e6, "!usdcRewardsPerYear");
    assertApproxEqAbs(res.usdcAprE8, 173 * 1e8, 1e8, "!usdcAprE8");
  }
}
