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

import {MultiStakingRewardsERC4626} from "../../core/utils/MultiStakingRewardsERC4626.sol";

contract StakingLPRewards is MultiStakingRewardsERC4626 {
  function initialize(
    string memory _name,
    string memory _symbol,
    address _stakingToken,
    address _governance,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration,
    address _staking
  ) external reinitializer(1) {
    __MultiStakingRewardsERC4626_init(
      _name, _symbol, _stakingToken, 21 days, _governance, _rewardToken1, _rewardToken2, _rewardsDuration, _staking
    );
  }
}
