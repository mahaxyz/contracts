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

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title Safety Pool
 * @author maha.xyz
 * @notice This is the main contract responsible for paying for bad debt.
 */
interface ISafetyPool {
  function coverBadDebt(uint256 amount) external;

  function initialize(
    string memory _name,
    string memory _symbol,
    address _zai,
    uint256 withdrawalDelay,
    address _governance,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration,
    address _stakingBoost
  ) external;

  function MANAGER_ROLE() external view returns (bytes32);

  function queueWithdrawal(uint256 shares) external;

  function withdrawalDelay() external view returns (uint256);

  function withdrawalAmount(address who) external view returns (uint256);

  function withdrawalTimestamp(address who) external view returns (uint256);

  function cancelWithdrawal() external;
}
