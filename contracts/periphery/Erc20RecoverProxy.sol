// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Contract to recover a ERC20 token from a proxy contract to a wallet
contract Erc20RecoverProxy is OwnableUpgradeable {
  function initialize(address _usdc, address _owner) external reinitializer(99) {
    IERC20 usdc = IERC20(_usdc);
    usdc.transfer(_owner, usdc.balanceOf(address(this)));
  }
}
