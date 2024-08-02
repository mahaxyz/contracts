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

pragma solidity 0.8.20;

/**
 * @title DD Plan Interface
 * @author maha.xyz, makerdao
 * @notice Plan contracts are contracts that the Hub uses to determine how much to change its position.
 */
interface IDDPlan {
  event Disable();
  event Enable();

  /**
   * @notice Determines what the position should be based on current assets
   * and the custom plan rules.
   * @param currentAssets asset balance from a specific pool in Dai [wad]
   * denomination
   * @return uint256 target assets the Hub should wind or unwind to in Dai
   */
  function getTargetAssets(uint256 currentAssets) external view returns (uint256);

  /**
   * @notice Reports whether the plan is active
   */
  function active() external view returns (bool);

  /**
   * @notice Enables the plan so that it would instruct the Hub to unwind
   * its entire position.
   * @dev Implementation should be permissioned.
   */
  function enable() external;

  /**
   * @notice Disables the plan so that it would instruct the Hub to unwind
   * its entire position.
   * @dev Implementation should be permissioned.
   */
  function disable() external;
}
