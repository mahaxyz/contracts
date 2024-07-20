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

/**
 * @title PSMEventsLib
 * @author maha.xyz
 * @notice This library defines events for the PSM contract
 */
library PSMEventsLib {
  /**
   * @notice Emitted when a user mints ZAI
   * @param destination Where the minted ZAI will be sent
   * @param shares The amount of ZAI minted
   * @param amount The amount of collateral taken
   * @param newDebt The current new debt of the PSM module
   * @param supplyCap The current supply cap of the PSM module
   * @param sender The address that called the mint function
   */
  event Mint(
    address indexed destination,
    uint256 indexed shares,
    uint256 indexed amount,
    uint256 newDebt,
    uint256 supplyCap,
    address sender
  );

  /**
   * @notice Emitted when the rate is updated
   * @dev Called by the admin
   * @param oldRate The old rate of ZAI/Collateral
   * @param newRate The new rate of ZAI/Collateral
   * @param sender The address that called the update function
   */
  event RateUpdated(uint256 indexed oldRate, uint256 indexed newRate, address sender);

  /**
   * @notice Emitted when a user redeems ZAI
   * @param destination Where the collateral will be sent
   * @param shares The amount of ZAI burnt
   * @param amount The amount of collateral taken out
   * @param newDebt The current new debt of the PSM module
   * @param supplyCap The current supply cap of the PSM module
   * @param sender The address that called the redeem function
   */
  event Redeem(
    address indexed destination,
    uint256 indexed shares,
    uint256 indexed amount,
    uint256 newDebt,
    uint256 supplyCap,
    address sender
  );

  /**
   * @notice Emitted when the supply cap is updated
   * @param _newSupplyCap The new supply cap
   * @param _newDebtCap The new debt cap
   * @param _oldSupplyCap The old supply cap
   * @param _oldDebtCap The old debt cap
   * @param sender The address that called the update function
   */
  event SupplyCapUpdated(
    uint256 indexed _newSupplyCap,
    uint256 indexed _newDebtCap,
    uint256 _oldSupplyCap,
    uint256 _oldDebtCap,
    address sender
  );

  /**
   * @notice Emitted when the fees are updated
   * @param _newMintFeeBps The new mint fee
   * @param _newRedeemFeeBps The new redeem fee
   * @param _oldMintFeeBps The old mint fee
   * @param _oldRedeemFeeBps The old redeem fee
   * @param sender The address that called the update function
   */
  event FeesUpdated(
    uint256 indexed _newMintFeeBps,
    uint256 indexed _newRedeemFeeBps,
    uint256 _oldMintFeeBps,
    uint256 _oldRedeemFeeBps,
    address sender
  );

  /**
   * @notice Emitted when the fee destination is updated
   * @param _newFeeDestination The new fee destination
   * @param _oldFeeDestination The old fee destination
   * @param sender The address that called the update function
   */
  event FeeDestinationUpdated(address indexed _newFeeDestination, address indexed _oldFeeDestination, address sender);
}
