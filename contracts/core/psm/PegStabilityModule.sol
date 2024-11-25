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
  uint256 private _rate;

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

  //// @inheritdoc IPegStabilityModule
  function updateRate(uint256 _newRate) external onlyOwner {
    _updateRate(_newRate);
  }

  /// @inheritdoc IPegStabilityModule
  function rate() public view override returns (uint256) {
    return _rate;
  }

  /**
   * @notice Updates the rate of ZAI/Collateral
   * @param rate_ the new rate of ZAI/Collateral
   */
  function _updateRate(uint256 rate_) internal {
    uint256 oldRate = rate_;
    _rate = rate_;
    emit PSMEventsLib.RateUpdated(oldRate, _rate, msg.sender);
  }

  function feesCollected() public pure override returns (uint256) {
    return 0;
  }
}
