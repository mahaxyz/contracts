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

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseBridge is OwnableUpgradeable {
  using SafeERC20 for IERC20;

  function __BaseBridge_init(address _owner) public initializer {
    __Ownable_init(_owner);
  }

  /**
   * @notice  Sweeps accidental ETH value sent to the contract
   * @dev     Restricted to be called by the Owner only.
   * @param   _amount  amount of native asset
   * @param   _to  destination address
   */
  function recoverNative(uint256 _amount, address _to) external onlyOwner {
    payable(_to).transfer(_amount);
  }

  /**
   * @notice  Sweeps accidental ERC20 value sent to the contract
   * @dev     Restricted to be called by the Owner only.
   * @param   _token  address of the ERC20 token
   * @param   _amount  amount of ERC20 token
   * @param   _to  destination address
   */
  function recoverERC20(address _token, uint256 _amount, address _to) external onlyOwner {
    IERC20(_token).safeTransfer(_to, _amount);
  }
}
