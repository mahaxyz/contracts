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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IZaiStablecoin is IERC20 {
  /**
   * @notice Used to mint ZAI
   * @dev This is only callable by verified minters approved by governance
   * @param _account The address to mint to
   * @param _amount The amount to mint
   */
  function mint(address _account, uint256 _amount) external;

  /**
   * @notice Role for minting/burning ZAI
   */
  function MANAGER_ROLE() external view returns (bytes32);

  /**
   * @notice Used to burn ZAI
   * @dev This is only callable by verified minters approved by governance
   * @param _account The address to burn from
   * @param _amount The amount to burn
   */
  function burn(address _account, uint256 _amount) external;

  /**
   * @notice Grants the manager role to an account
   * @dev Can only be called by governance
   * @param _account The account to grant the role to
   */
  function grantManagerRole(address _account) external;

  /**
   * @notice Revokes the manager role to an account
   * @dev Can only be called by governance
   * @param _account The account to revoke the role from
   */
  function revokeManagerRole(address _account) external;

  /**
   * @notice Checks if an address is an approved manager
   * @param _account The address to check
   * @return what True iff the address is a manager
   */
  function isManager(address _account) external view returns (bool what);
}
