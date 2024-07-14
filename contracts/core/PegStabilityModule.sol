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

import {IZaiStablecoin} from '../interfaces/IZaiStablecoin.sol';
import {IPegStabilityModule} from '../interfaces/core/IPegStabilityModule.sol';

import {PSMEventsLib} from '../interfaces/events/PSMEventsLib.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

/**
 * @title Peg Stability Module
 * @author maha.xyz
 * @notice Used to mint ZAI with collateral at a pre-defined rate
 */
contract PegStabilityModule is Ownable, ReentrancyGuard, IPegStabilityModule {
  /// @inheritdoc IPegStabilityModule
  IZaiStablecoin public zai;

  /// @inheritdoc IPegStabilityModule
  IERC20 public collateral;

  /// @inheritdoc IPegStabilityModule
  uint256 public supplyCap;

  /// @inheritdoc IPegStabilityModule
  uint256 public debtCap;

  /// @inheritdoc IPegStabilityModule
  uint256 public debt;

  /// @inheritdoc IPegStabilityModule
  uint256 public rate;

  constructor(
    address _zai,
    address _collateral,
    address _governance,
    uint256 _newRate,
    uint256 _supplyCap,
    uint256 _debtCap
  ) Ownable(_governance) {
    zai = IZaiStablecoin(_zai);
    collateral = IERC20(_collateral);
    supplyCap = _supplyCap;
    debtCap = _debtCap;

    _updateCaps(_supplyCap, _debtCap);
    _updateRate(_newRate);
  }

  /// @inheritdoc IPegStabilityModule
  function mint(address dest, uint256 shares) external nonReentrant {
    uint256 amount = toCollateralAmount(shares);

    require(collateral.balanceOf(address(this)) + amount <= supplyCap, 'supply cap exceeded');
    require(debt + shares <= debtCap, 'debt cap exceeded');

    collateral.transferFrom(msg.sender, address(this), amount);
    zai.mint(dest, shares);

    debt += shares;
    emit PSMEventsLib.Mint(dest, shares, amount, debt, supplyCap, msg.sender);
  }

  /// @inheritdoc IPegStabilityModule
  function redeem(address dest, uint256 shares) external nonReentrant {
    uint256 amount = toCollateralAmount(shares);

    zai.transferFrom(msg.sender, address(this), shares);
    zai.burn(address(this), shares);
    collateral.transfer(dest, amount);

    debt -= shares;
    emit PSMEventsLib.Redeem(dest, shares, amount, debt, supplyCap, msg.sender);
  }

  /// @inheritdoc IPegStabilityModule
  function updateCaps(uint256 _supplyCap, uint256 _debtCap) external onlyOwner {
    _updateCaps(_supplyCap, _debtCap);
  }

  /// @inheritdoc IPegStabilityModule
  function updateRate(uint256 _newRate) external onlyOwner {
    _updateRate(_newRate);
  }

  /// @inheritdoc IPegStabilityModule
  function toCollateralAmount(uint256 _amount) public view returns (uint256) {
    return (_amount * rate) / 1e18;
  }

  function _updateCaps(uint256 _supplyCap, uint256 _debtCap) internal {
    uint256 oldSupplyCap = supplyCap;
    uint256 olsDebtCap = debtCap;

    supplyCap = _supplyCap;
    debtCap = _debtCap;

    emit PSMEventsLib.SupplyCapUpdated(_supplyCap, _debtCap, oldSupplyCap, olsDebtCap, msg.sender);
  }

  function _updateRate(uint256 _rate) internal {
    uint256 oldRate = rate;
    rate = _rate;
    emit PSMEventsLib.RateUpdated(oldRate, _rate, msg.sender);
  }
}
