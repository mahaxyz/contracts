// SPDX-License-Identifier: GPL-3.0

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// The Stable Money of the Ethermind

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity 0.8.21;

import {IStablecoin} from "../interfaces/IStablecoin.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

abstract contract StablecoinBase is ERC20FlashMint, ERC20Permit, AccessControlEnumerable, IStablecoin {
  /// @inheritdoc IStablecoin
  bytes32 public MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /**
   * Initializes the stablecoin
   */
  constructor(string memory name, string memory symbol, address _owner) ERC20(name, symbol) ERC20Permit(name) {
    _mint(msg.sender, 1e18);
    _burn(msg.sender, 1e18);
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
  }

  /// @inheritdoc IStablecoin
  function grantManagerRole(address _account) external {
    grantRole(MANAGER_ROLE, _account);
  }

  /// @inheritdoc IStablecoin
  function revokeManagerRole(address _account) external {
    revokeRole(MANAGER_ROLE, _account);
  }

  /// @inheritdoc IStablecoin
  function isManager(address _account) external view returns (bool what) {
    what = hasRole(MANAGER_ROLE, _account);
  }

  /// @inheritdoc IStablecoin
  function mint(address _account, uint256 _amount) external onlyRole(MANAGER_ROLE) {
    _mint(_account, _amount);
  }

  /// @inheritdoc IStablecoin
  function burn(address _account, uint256 _amount) external onlyRole(MANAGER_ROLE) {
    _burn(_account, _amount);
  }
}
