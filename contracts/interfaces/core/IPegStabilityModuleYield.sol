// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import {IStablecoin} from "../IStablecoin.sol";

import {IPegStabilityModule} from "./IPegStabilityModule.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title Peg Stability Module Yield Interface
 * @dev Interface for the Peg Stability Module that allows minting ZAI using ERC4626-compatible collateral, supporting
 * yield generation.
 *      Enables minting and redeeming of ZAI, adjusting caps, rates, and fees, and collecting yield.
 * @notice This interface defines the functions to mint and redeem ZAI at a pre-defined rate using yield-bearing
 * collateral.
 * @custom:author maha.xyz
 */
interface IPegStabilityModuleYield is IPegStabilityModule {
  /**
   * @notice Transfers accumulated yield to the designated fee distributor.
   *
   */
  function transferYieldToFeeDistributor() external;
}
