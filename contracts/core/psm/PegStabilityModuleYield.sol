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

import {IStablecoin} from "../../interfaces/IStablecoin.sol";
import {IPegStabilityModuleYield} from "../../interfaces/core/IPegStabilityModuleYield.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {PSMErrors} from "../../interfaces/errors/PSMErrors.sol";
import {PSMEventsLib} from "../../interfaces/events/PSMEventsLib.sol";

contract PegStabilityModuleYield is
  Ownable2StepUpgradeable,
  ReentrancyGuardUpgradeable,
  IPegStabilityModuleYield
{
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC4626;

  uint256 public supplyCap;
  uint256 public debtCap;
  uint256 public rate;
  uint256 public mintFeeBps;
  uint256 public redeemFeeBps;

  uint256 public debt;

  IStablecoin public usdz;
  IERC4626 public collateral;
  address public feeDistributor;

  uint256 public constant MAX_FEE_BPS = 10_000;

  function initialize(
    address usdz_,
    address collateral_,
    address governance,
    uint256 newRate_,
    uint256 supplyCap_,
    uint256 debtCap_,
    uint256 mintFeeBps_,
    uint256 redeemFeeBps_,
    address feeDistributor_
  ) external initializer {
    ensureNonZeroAddress(usdz_);
    ensureNonZeroAddress(collateral_);
    ensureNonZeroAddress(governance);
    ensureNonZeroAddress(feeDistributor_);

    ensureNonZeroValue(newRate_);
    ensureNonZeroValue(supplyCap_);
    ensureNonZeroValue(debtCap_);

    usdz = IStablecoin(usdz_);
    collateral = IERC4626(collateral_);

    __Ownable_init(governance);
    __ReentrancyGuard_init();

    _updateFees(mintFeeBps_, redeemFeeBps_);
    _updateRate(newRate_);
    _updateCaps(supplyCap_, debtCap_);
    _updateFeeDistributor(feeDistributor_);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function mint(address dest, uint256 shares) external nonReentrant {
    uint256 amount = toCollateralAmountWithFee(shares, mintFeeBps);

    if (amount == 0) revert PSMErrors.NotZeroValue();
    if (shares == 0) revert PSMErrors.NotZeroValue();

    if (collateral.balanceOf(address(this)) + amount > supplyCap)
      revert PSMErrors.SupplyCapReached();
    if (debt + shares > debtCap) revert PSMErrors.DebtCapReached();

    collateral.safeTransferFrom(msg.sender, address(this), amount);
    usdz.mint(dest, shares);

    debt += shares;
    emit PSMEventsLib.Mint(dest, shares, amount, debt, supplyCap, msg.sender);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function redeem(address dest, uint256 shares) external nonReentrant {
    uint256 amount = toCollateralAmountWithFeeInverse(shares, redeemFeeBps);

    if (amount == 0) revert PSMErrors.NotZeroValue();
    if (shares == 0) revert PSMErrors.NotZeroValue();

    usdz.transferFrom(msg.sender, address(this), shares);
    usdz.burn(address(this), shares);
    collateral.safeTransfer(dest, amount);

    debt -= shares;
    emit PSMEventsLib.Redeem(dest, shares, amount, debt, supplyCap, msg.sender);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function updateCaps(uint256 _supplyCap, uint256 _debtCap) external onlyOwner {
    _updateCaps(_supplyCap, _debtCap);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function updateRate(uint256 _newRate) external onlyOwner {
    _updateRate(_newRate);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function updateFees(
    uint256 _mintFeeBps,
    uint256 _redeemFeeBps
  ) external onlyOwner {
    _updateFees(_mintFeeBps, _redeemFeeBps);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function updateFeeDistributor(address _newFeeDistributor) external onlyOwner {
    _updateFeeDistributor(_newFeeDistributor);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function toCollateralAmount(uint256 _amount) public view returns (uint256) {
    return (_amount * rate) / 1e18;
  }

  /// @inheritdoc IPegStabilityModuleYield
  function toCollateralAmountWithFee(
    uint256 _amount,
    uint256 _fee
  ) public view returns (uint256) {
    return (toCollateralAmount(_amount) * (MAX_FEE_BPS + _fee)) / MAX_FEE_BPS;
  }

  /// @inheritdoc IPegStabilityModuleYield
  function toCollateralAmountWithFeeInverse(
    uint256 _amount,
    uint256 _fee
  ) public view returns (uint256) {
    return (toCollateralAmount(_amount) * (MAX_FEE_BPS - _fee)) / MAX_FEE_BPS;
  }

  /// @inheritdoc IPegStabilityModuleYield
  function mintAmountIn(
    uint256 amountAssetsIn
  ) external view returns (uint256 shares) {
    shares =
      (amountAssetsIn * 1e18 * MAX_FEE_BPS) /
      (MAX_FEE_BPS + mintFeeBps) /
      rate;
  }

  /// @inheritdoc IPegStabilityModuleYield
  function redeemAmountOut(
    uint256 amountAssetsOut
  ) external view returns (uint256 shares) {
    shares =
      (amountAssetsOut * 1e18 * MAX_FEE_BPS) /
      (MAX_FEE_BPS - redeemFeeBps) /
      rate;
  }

  /// @inheritdoc IPegStabilityModuleYield
  function feesCollected() public view returns (uint256) {
    return collateral.balanceOf(address(this)) - toCollateralAmount(debt);
  }

  function ensureNonZeroAddress(address address_) internal pure {
    if (address_ == address(0)) {
      revert PSMErrors.NotZeroAddress();
    }
  }

  function ensureNonZeroValue(uint256 value_) internal pure {
    if (value_ == 0) {
      revert PSMErrors.NotZeroValue();
    }
  }

  function _updateCaps(uint256 _supplyCap, uint256 _debtCap) internal {
    uint256 oldSupplyCap = supplyCap;
    uint256 olsDebtCap = debtCap;

    supplyCap = _supplyCap;
    debtCap = _debtCap;

    emit PSMEventsLib.SupplyCapUpdated(
      _supplyCap,
      _debtCap,
      oldSupplyCap,
      olsDebtCap,
      msg.sender
    );
  }

  /**
   * @notice Updates the rate of USDz/Collateral
   * @param _rate the new rate of USDz/Collateral
   */
  function _updateRate(uint256 _rate) internal {
    uint256 oldRate = rate;
    rate = _rate;
    emit PSMEventsLib.RateUpdated(oldRate, _rate, msg.sender);
  }

  /**
   * @notice Updates the fee destination
   * @param _newFeeDistributor the new fee destination
   */
  function _updateFeeDistributor(address _newFeeDistributor) internal {
    address oldFeeDestination = feeDistributor;
    feeDistributor = _newFeeDistributor;
    emit PSMEventsLib.FeeDestinationUpdated(
      _newFeeDistributor,
      oldFeeDestination,
      msg.sender
    );
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
    emit PSMEventsLib.FeesUpdated(
      _mintFeeBps,
      _redeemFeeBps,
      oldMintFeeBps,
      oldRedeemFeeBps,
      msg.sender
    );
  }

  /**
   * @notice Calculates the yield generated by the yield-bearing collateral and transfers it to the fee collector.
   * @dev This function checks if the total asset value of the collateral exceeds the current debt.
   *      If yield is present, it converts the excess asset value to shares and transfers it to the fee collector.
   *      Uses ERC-4626's `convertToAssets` and `convertToShares` for accurate conversions.
   * Requirements:
   * - `feeCollector` must be a valid address.
   * - `collateral` should be an ERC-4626 token that supports `convertToAssets` and `convertToShares`.
   *
   */
  function transferYieldToFeeDistributor() public {
    uint256 bal = collateral.balanceOf(address(this));
    uint256 val = collateral.convertToAssets(bal);
    if (val > debt) {
      uint256 yield = collateral.convertToShares(val - debt);
      collateral.safeTransfer(feeDistributor, yield);
    }
  }
}
