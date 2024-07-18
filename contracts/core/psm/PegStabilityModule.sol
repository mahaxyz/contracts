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

import {IZaiStablecoin} from "../../interfaces/IZaiStablecoin.sol";
import {IPegStabilityModule} from "../../interfaces/core/IPegStabilityModule.sol";
import {PSMEventsLib} from "../../interfaces/events/PSMEventsLib.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title Peg Stability Module
 * @author maha.xyz
 * @notice Used to mint ZAI with collateral at a pre-defined rate
 */
contract PegStabilityModule is OwnableUpgradeable, ReentrancyGuardUpgradeable, IPegStabilityModule {
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

  /// @inheritdoc IPegStabilityModule
  uint256 public mintFeeBps;

  /// @inheritdoc IPegStabilityModule
  uint256 public redeemFeeBps;

  /// @inheritdoc IPegStabilityModule
  address public feeDestination;

  /// @inheritdoc IPegStabilityModule
  uint256 public MAX_FEE_BPS;

  /// @inheritdoc IPegStabilityModule
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
  ) external reinitializer(1) {
    zai = IZaiStablecoin(_zai);
    collateral = IERC20(_collateral);

    __Ownable_init(_governance);
    __ReentrancyGuard_init();

    _updateFees(_mintFeeBps, _redeemFeeBps);
    _updateCaps(_supplyCap, _debtCap);
    _updateRate(_newRate);
    _updateFeeDestination(_feeDestination);

    MAX_FEE_BPS = 10_000;
  }

  /// @inheritdoc IPegStabilityModule
  function mint(address dest, uint256 shares) external nonReentrant {
    uint256 amount = toCollateralAmountWithFee(shares, mintFeeBps);

    require(collateral.balanceOf(address(this)) + amount <= supplyCap, "supply cap exceeded");
    require(debt + shares <= debtCap, "debt cap exceeded");

    collateral.transferFrom(msg.sender, address(this), amount);
    zai.mint(dest, shares);

    debt += shares;
    emit PSMEventsLib.Mint(dest, shares, amount, debt, supplyCap, msg.sender);
  }

  /// @inheritdoc IPegStabilityModule
  function redeem(address dest, uint256 shares) external nonReentrant {
    uint256 amount = toCollateralAmountWithFeeInverse(shares, redeemFeeBps);

    zai.transferFrom(msg.sender, address(this), shares);
    zai.burn(address(this), shares);
    collateral.transfer(dest, amount);

    debt -= shares;
    emit PSMEventsLib.Redeem(dest, shares, amount, debt, supplyCap, msg.sender);
  }

  function sweepFees() external {
    collateral.transfer(feeDestination, feesCollected());
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
  function updateFees(uint256 _mintFeeBps, uint256 _redeemFeeBps) external onlyOwner {
    _updateFees(_mintFeeBps, _redeemFeeBps);
  }

  /// @inheritdoc IPegStabilityModule
  function updateFeeDestination(address _feeDestination) external onlyOwner {
    _updateFeeDestination(_feeDestination);
  }

  /// @inheritdoc IPegStabilityModule
  function toCollateralAmount(uint256 _amount) public view returns (uint256) {
    return (_amount * rate) / 1e18;
  }

  /// @inheritdoc IPegStabilityModule
  function toCollateralAmountWithFee(uint256 _amount, uint256 _fee) public view returns (uint256) {
    return (toCollateralAmount(_amount) * (MAX_FEE_BPS + _fee)) / MAX_FEE_BPS;
  }

  /// @inheritdoc IPegStabilityModule
  function toCollateralAmountWithFeeInverse(uint256 _amount, uint256 _fee) public view returns (uint256) {
    return (toCollateralAmount(_amount) * (MAX_FEE_BPS - _fee)) / MAX_FEE_BPS;
  }

  /// @inheritdoc IPegStabilityModule
  function feesCollected() public view returns (uint256) {
    return collateral.balanceOf(address(this)) - debt;
  }

  function _updateCaps(uint256 _supplyCap, uint256 _debtCap) internal {
    uint256 oldSupplyCap = supplyCap;
    uint256 olsDebtCap = debtCap;

    supplyCap = _supplyCap;
    debtCap = _debtCap;

    emit PSMEventsLib.SupplyCapUpdated(_supplyCap, _debtCap, oldSupplyCap, olsDebtCap, msg.sender);
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

  /**
   * @notice Updates the fee destination
   * @param _feeDestination the new fee destination
   */
  function _updateFeeDestination(address _feeDestination) internal {
    address oldFeeDestination = feeDestination;
    feeDestination = _feeDestination;
    emit PSMEventsLib.FeeDestinationUpdated(_feeDestination, oldFeeDestination, msg.sender);
  }

  /**
   * @notice Updates the mint and redeem fees
   * @param _mintFeeBps the new mint fee in BPS
   * @param _redeemFeeBps the new redeem fee in BPS
   */
  function _updateFees(uint256 _mintFeeBps, uint256 _redeemFeeBps) internal {
    uint256 oldMintFeeBps = mintFeeBps;
    uint256 oldRedeemFeeBps = redeemFeeBps;
    mintFeeBps = _mintFeeBps;
    redeemFeeBps = _redeemFeeBps;
    emit PSMEventsLib.FeesUpdated(_mintFeeBps, _redeemFeeBps, oldMintFeeBps, oldRedeemFeeBps, msg.sender);
  }
}
