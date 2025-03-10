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

import {IMultiStakingRewardsERC4626} from "../../interfaces/core/IMultiStakingRewardsERC4626.sol";
import {ZaiFeeCollectorCronBase} from "./ZaiFeeCollectorCronBase.sol";

contract ZaiFeeCollectorCronMainnet is ZaiFeeCollectorCronBase {
  address public collector;

  IMultiStakingRewardsERC4626 public safetyPoolZai;
  IMultiStakingRewardsERC4626 public stakerMahaZai;
  IMultiStakingRewardsERC4626 public stakerUsdcZai;

  address public treasury;

  function init(
    address _rewardToken,
    address _weth,
    address _odos,
    address[] memory _tokens,
    address _gelatoooooo,
    address _stakerMahaZai,
    address _stakerUsdcZai,
    address _safetyPoolZai,
    address _governance
  ) public reinitializer(1) {
    __ZaiFeeCollectorCronBase_init(_rewardToken, _weth, _odos, _tokens, _gelatoooooo, _governance);

    safetyPoolZai = IMultiStakingRewardsERC4626(_safetyPoolZai);
    stakerMahaZai = IMultiStakingRewardsERC4626(_stakerMahaZai);
    stakerUsdcZai = IMultiStakingRewardsERC4626(_stakerUsdcZai);

    rewardToken.approve(_stakerMahaZai, type(uint256).max);
    rewardToken.approve(_stakerUsdcZai, type(uint256).max);
    rewardToken.approve(_safetyPoolZai, type(uint256).max);
  }

  function swap(bytes memory data) public {
    require(msg.sender == owner() || msg.sender == gelatoooooo, "who dis?");

    // swap on odos
    (bool success,) = odos.call(data);
    require(success, "odos call failed");

    // send all rewardToken to the destination
    uint256 amt = rewardToken.balanceOf(address(this));

    uint256 treasuryAmt = amt / 10; // give 10% to the treasury
    uint256 zaiMahaAmt = amt / 5; // 20% to ZAI/MAHA staking
    uint256 zaiSafetyPoolAmt = amt / 10; // give 10% to ZAI stability pool
    uint256 zaiUsdcAmt = amt - treasuryAmt - zaiMahaAmt - zaiSafetyPoolAmt; // 60% to ZAI/USDC staking

    rewardToken.transfer(treasury, treasuryAmt);
    stakerMahaZai.notifyRewardAmount(rewardToken, zaiMahaAmt);
    stakerUsdcZai.notifyRewardAmount(rewardToken, zaiUsdcAmt);
    safetyPoolZai.notifyRewardAmount(rewardToken, zaiSafetyPoolAmt);

    // emit events
    emit RevenueCollected(amt);
    emit RevenueDistributed(treasury, treasuryAmt);
    emit RevenueDistributed(address(stakerMahaZai), zaiMahaAmt);
    emit RevenueDistributed(address(safetyPoolZai), zaiSafetyPoolAmt);
    emit RevenueDistributed(address(stakerUsdcZai), zaiUsdcAmt);
  }
}
