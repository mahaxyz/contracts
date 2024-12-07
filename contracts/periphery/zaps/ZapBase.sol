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

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title ZapBase
 * @dev This contract allows users to perform a Zap operation by swapping collateral for zai tokens, adding liquidity to
 * curve LP, and staking the LP tokens.
 */
abstract contract ZapBase {
  IERC4626 public staking;

  IERC20Metadata public pool;

  IERC20Metadata public zai;

  IERC20Metadata public collateral;

  uint256 public decimalOffset;

  address public me;

  error OdosSwapFailed();
  error CollateralTransferFailed();
  error TokenTransferFailed();

  event Zapped(
    address indexed user, uint256 indexed collateralAmount, uint256 indexed zaiAmount, uint256 newStakedAmount
  );

  /**
   * @dev Initializes the contract with the required contracts
   */
  constructor(address _staking) {
    staking = IERC4626(_staking);
    pool = IERC20Metadata(staking.asset());
    pool.approve(_staking, type(uint256).max);
    me = address(this);
  }

  function _sweep(IERC20 token) internal {
    uint256 tokenB = token.balanceOf(address(this));
    if (tokenB > 0 && !token.transfer(msg.sender, tokenB)) {
      revert TokenTransferFailed();
    }
  }
}
