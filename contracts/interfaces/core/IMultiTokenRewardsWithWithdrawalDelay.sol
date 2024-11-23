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

import {IMultiStakingRewardsERC4626} from "./IMultiStakingRewardsERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMultiTokenRewardsWithWithdrawalDelay is IMultiStakingRewardsERC4626 {
  event WithdrawalQueueUpdated(uint256 indexed amt, uint256 indexed unlockTime, address indexed caller);

  function queueWithdrawal(uint256 shares) external;

  function withdrawalDelay() external view returns (uint256);

  function withdrawalAmount(address who) external view returns (uint256);

  function withdrawalTimestamp(address who) external view returns (uint256);

  function cancelWithdrawal() external;
}
