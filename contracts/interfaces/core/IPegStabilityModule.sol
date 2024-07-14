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

import {IZaiStablecoin} from '../IZaiStablecoin.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @title Peg Stability Module
 * @author maha.xyz
 * @notice Used to mint ZAI with collateral at a pre-defined rate
 */
interface IPegStabilityModule {
  /**
   * @notice Returns the Zai stablecoin
   */
  function zai() external returns (IZaiStablecoin);

  /**
   * @notice Returns the collateral token
   */
  function collateral() external returns (IERC20);

  /**
   * @notice Returns the supply cap
   */
  function supplyCap() external returns (uint256);

  /**
   * @notice Returns the debt cap
   */
  function debtCap() external returns (uint256);

  /**
   * @notice Returns the current debt held in this vault
   */
  function debt() external returns (uint256);

  /**
   * @notice Returns the current rate of ZAI/Collateral
   */
  function rate() external returns (uint256);

  /**
   * @notice Mints ZAI with collateral
   * @dev This contract calculates how much collateral should be taken
   * @param destination Where the minted ZAI will be sent
   * @param shares The amount of zai to mint
   */
  function mint(address destination, uint256 shares) external;

  /**
   * @notice Redeems ZAI for collateral
   * @dev This contract calculates how much collateral should be given
   * @param destination Where the collateral will be sent
   * @param shares The amount of zai to redeem
   */
  function redeem(address destination, uint256 shares) external;

  /**
   * @notice Updates the supply and debt caps
   * @dev Only callable by the admin
   * @param _supplyCap How much collateral can be taken
   * @param _debtCap How much debt can be held
   */
  function updateCaps(uint256 _supplyCap, uint256 _debtCap) external;

  /**
   * @notice Updates the rate of ZAI/Collateral
   * @dev Only callable by the admin
   * @param _newRate The new rate of ZAI/Collateral
   */
  function updateRate(uint256 _newRate) external;

  /**
   * @notice Converts ZAI amount to collateral
   * @param _amount The amount of ZAI
   * @return collateralAmount The amount of collateral
   */
  function toCollateralAmount(uint256 _amount) external view returns (uint256 collateralAmount);
}
