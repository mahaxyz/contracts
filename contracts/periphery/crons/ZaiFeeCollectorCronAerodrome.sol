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

/// @title Fee collector cron job for Zai on Base
/// @author maha.xyz
/// @notice On base we give 60% of our revenue to aerodrome voters and 40% to the treasury
contract ZaiFeeCollectorCronAerodrome is ZaiFeeCollectorCronBase {
  IMultiStakingRewardsERC4626 public safetyPoolZai;
  IMultiStakingRewardsERC4626 public stakerMahaZai;
  IMultiStakingRewardsERC4626 public stakerUsdcZai;

  address public treasury;
  address public aerodromeBribe;
  address public connextBridge;

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

    uint256 aerodromeAmt = amt * 3 / 5; // give 60% to the treasury
    uint256 zaiMainnetBridgeAmt = amt - aerodromeAmt; // send the rest back to mainnet treasury

    // todo send the usdc back via connext to mainnet
    // todo send the usdc as rewards directly to aerodrome

    // emit events
    emit RevenueCollected(amt);
    emit RevenueDistributed(aerodromeBribe, aerodromeAmt);
    emit RevenueDistributed(address(stakerMahaZai), zaiMainnetBridgeAmt);
  }
}
