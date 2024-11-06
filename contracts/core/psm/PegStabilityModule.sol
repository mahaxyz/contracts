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

import {IPegStabilityModule} from "../../interfaces/core/IPegStabilityModule.sol";
import {PSMErrors} from "../../interfaces/errors/PSMErrors.sol";
import {PSMEventsLib} from "../../interfaces/events/PSMEventsLib.sol";
import {IPegStabilityModule, PegStabilityModuleBase} from "./PegStabilityModuleBase.sol";

/**
 * @title Peg Stability Module
 * @author maha.xyz
 * @notice Used to mint ZAI with collateral at a pre-defined rate
 * @dev https://docs.maha.xyz/mechanics/peg-mechanics/peg-stablility-module-psm
 */
contract PegStabilityModule is PegStabilityModuleBase {
  /// @inheritdoc IPegStabilityModule
  uint256 public rate;

  function initialize(
    address _zai,
    address _collateral,
    address _governance,
    uint256 _newRate,
    uint256 _supplyCap,
    uint256 _debtCap,
    uint256 _mintFeeBps,
    uint256 _redeemFeeBps,
    address _feeDestination
  ) external reinitializer(2) {
    __PegStabilityModule_init(
      _zai, _collateral, _governance, _supplyCap, _debtCap, _mintFeeBps, _redeemFeeBps, _feeDestination
    );

    if (_newRate == 0) {
      revert PSMErrors.NotZeroValue();
    }
    _updateRate(_newRate);
  }

  /// @inheritdoc IPegStabilityModule
  function updateRate(uint256 _newRate) external onlyOwner {
    _updateRate(_newRate);
  }

  /// @inheritdoc IPegStabilityModule
  function toCollateralAmount(uint256 _amount) public view override returns (uint256) {
    return (_amount * rate) / 1e18;
  }

  /// @inheritdoc IPegStabilityModule
  function mintAmountIn(uint256 amountAssetsIn) external view override returns (uint256 shares) {
    shares = (amountAssetsIn * 1e18 * MAX_FEE_BPS) / (MAX_FEE_BPS + mintFeeBps) / rate;
  }

  /// @inheritdoc IPegStabilityModule
  function redeemAmountOut(uint256 amountAssetsOut) external view override returns (uint256 shares) {
    shares = (amountAssetsOut * 1e18 * MAX_FEE_BPS) / (MAX_FEE_BPS - redeemFeeBps) / rate;
  }

  /**
   * @notice Updates the rate of ZAI/Collateral
   * @param _rate the new rate of ZAI/Collateral
   */
  function _updateRate(uint256 _rate) internal {
    uint256 oldRate = rate;
    rate = _rate;
    emit PSMEventsLib.RateUpdated(oldRate, _rate, msg.sender);
  }
}
