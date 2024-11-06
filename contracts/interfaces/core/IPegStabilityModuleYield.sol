// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import {IStablecoin} from "../IStablecoin.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title Peg Stability Module Yield Interface
 * @dev Interface for the Peg Stability Module that allows minting USDz using ERC4626-compatible collateral, supporting yield generation.
 *      Enables minting and redeeming of USDz, adjusting caps, rates, and fees, and collecting yield.
 * @notice This interface defines the functions to mint and redeem USDz at a pre-defined rate using yield-bearing collateral.
 * @custom:author maha.xyz
 */
interface IPegStabilityModuleYield {
  /**
   * @notice Returns the USDz stablecoin.
   * @return usdz The address of the USDz stablecoin contract.
   */
  function usdz() external returns (IStablecoin);

  /**
   * @notice Returns the ERC4626-compatible collateral token.
   * @return collateral The address of the collateral token contract.
   */
  function collateral() external returns (IERC4626);

  /**
   * @notice Returns the maximum allowable supply of USDz.
   * @return supplyCap The maximum supply of USDz.
   */
  function supplyCap() external returns (uint256);

  /**
   * @notice Returns the maximum allowable debt in USDz.
   * @return debtCap The maximum debt limit for USDz.
   */
  function debtCap() external returns (uint256);

  /**
   * @notice Returns the current debt held by the module in USDz.
   * @return debt The current amount of debt in USDz.
   */
  function debt() external returns (uint256);

  /**
   * @notice Returns the current exchange rate of USDz to collateral.
   * @return rate The current rate of USDz/Collateral.
   */
  function rate() external returns (uint256);

  /**
   * @notice Returns the minting fee in basis points (BPS).
   * @return mintFeeBps The mint fee in BPS.
   */
  function mintFeeBps() external returns (uint256);

  /**
   * @notice Returns the address where collected fees are sent.
   * @return feeCollector The address designated to collect fees.
   */
  function feeDistributor() external returns (address);

  /**
   * @notice Returns the redeem fee in basis points (BPS).
   * @return redeemFeeBps The redeem fee in BPS.
   */
  function redeemFeeBps() external returns (uint256);

  /**
   * @notice Returns the maximum fee limit in BPS that can be charged.
   * @return MAX_FEE_BPS The maximum allowable fee in BPS.
   */
  function MAX_FEE_BPS() external returns (uint256);

  /**
   * @notice Mints USDz using collateral.
   * @dev Calculates the amount of collateral required for minting the specified USDz.
   * @param destination The address receiving the minted USDz.
   * @param shares The amount of USDz to mint.
   */
  function mint(address destination, uint256 shares) external;

  /**
   * @notice Redeems USDz in exchange for collateral.
   * @dev Calculates the amount of collateral to be provided for the redeemed USDz.
   * @param destination The address receiving the collateral.
   * @param shares The amount of USDz to redeem.
   */
  function redeem(address destination, uint256 shares) external;

  /**
   * @notice Updates the supply and debt caps.
   * @dev Restricted to the contract's administrator.
   * @param _supplyCap The new supply cap for USDz.
   * @param _debtCap The new debt cap for USDz.
   */
  function updateCaps(uint256 _supplyCap, uint256 _debtCap) external;

  /**
   * @notice Updates the exchange rate between USDz and collateral.
   * @dev Restricted to the contract's administrator.
   * @param _newRate The new rate of USDz/Collateral.
   */
  function updateRate(uint256 _newRate) external;

  /**
   * @notice Converts an amount of USDz to its equivalent collateral value.
   * @param _amount The amount of USDz.
   * @return collateralAmount The equivalent collateral amount.
   */
  function toCollateralAmount(
    uint256 _amount
  ) external view returns (uint256 collateralAmount);

  /**
   * @notice Converts an amount of USDz to collateral with fees included.
   * @dev Fee is calculated as (amount * (MAX_FEE_BPS + fee)) / MAX_FEE_BPS.
   * @param _amount The amount of USDz.
   * @param _fee The fee in BPS to be added.
   * @return The collateral amount with fees included.
   */
  function toCollateralAmountWithFee(
    uint256 _amount,
    uint256 _fee
  ) external view returns (uint256);

  /**
   * @notice Converts an amount of USDz to collateral with fees excluded.
   * @dev Fee is calculated as (amount * (MAX_FEE_BPS - fee)) / MAX_FEE_BPS.
   * @param _amount The amount of USDz.
   * @param _fee The fee in BPS to be subtracted.
   * @return The collateral amount with fees excluded.
   */
  function toCollateralAmountWithFeeInverse(
    uint256 _amount,
    uint256 _fee
  ) external view returns (uint256);

  /**
   * @notice Calculates the USDz amount to mint for a given collateral input.
   * @param amountAssetsIn The collateral amount.
   * @return shares The corresponding USDz amount to mint.
   */
  function mintAmountIn(
    uint256 amountAssetsIn
  ) external view returns (uint256 shares);

  /**
   * @notice Calculates the USDz amount to redeem for a given collateral output.
   * @param amountAssetsOut The collateral amount.
   * @return shares The corresponding USDz amount to redeem.
   */
  function redeemAmountOut(
    uint256 amountAssetsOut
  ) external view returns (uint256 shares);

  /**
   * @notice Returns the total fees collected by the protocol in USDz.
   * @return fees The amount of fees collected.
   */
  function feesCollected() external view returns (uint256 fees);

  /**
   * @notice Updates the minting and redeeming fees.
   * @param _mintFeeBps The new mint fee in BPS.
   * @param _redeemFeeBps The new redeem fee in BPS.
   */
  function updateFees(uint256 _mintFeeBps, uint256 _redeemFeeBps) external;

  /**
   * @notice Updates the address for fee collection.
   * @dev Restricted to the contract's administrator.
   * @param _feeCollector The new fee collector address.
   */
  function updateFeeDistributor(address _feeCollector) external;

  /**
   * @notice Initializes the Peg Stability Module with necessary parameters.
   * @param usdz_ The USDz stablecoin address.
   * @param collateral_ The collateral token address.
   * @param governance_ The governance address.
   * @param newRate_ The initial USDz/Collateral rate.
   * @param supplyCap_ The initial supply cap.
   * @param debtCap_ The initial debt cap.
   * @param mintFeeBps_ The mint fee in BPS.
   * @param redeemFeeBps_ The redeem fee in BPS.
   * @param feeCollector_ The initial fee collection address.
   */
  function initialize(
    address usdz_,
    address collateral_,
    address governance_,
    uint256 newRate_,
    uint256 supplyCap_,
    uint256 debtCap_,
    uint256 mintFeeBps_,
    uint256 redeemFeeBps_,
    address feeCollector_
  ) external;

  /**
   * @notice Transfers accumulated yield to the designated fee distributor.
   *
   */
  function transferYieldToFeeDistributor() external;
}
