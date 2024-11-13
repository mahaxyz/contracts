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

contract PegStabilityModuleYield is Ownable2StepUpgradeable, ReentrancyGuardUpgradeable, IPegStabilityModuleYield {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC4626;

  uint256 public supplyCap;
  uint256 public debtCap;
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

    ensureNonZeroValue(supplyCap_);
    ensureNonZeroValue(debtCap_);

    usdz = IStablecoin(usdz_);
    collateral = IERC4626(collateral_);

    __Ownable_init(governance);
    __ReentrancyGuard_init();

    _updateFees(mintFeeBps_, redeemFeeBps_);
    _updateCaps(supplyCap_, debtCap_);
    _updateFeeDistributor(feeDistributor_);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function mint(address dest, uint256 shares) external nonReentrant {
    uint256 amount = toCollateralAmountWithFee(shares, mintFeeBps);

    if (amount == 0) revert PSMErrors.NotZeroValue();
    if (shares == 0) revert PSMErrors.NotZeroValue();

    if (collateral.balanceOf(address(this)) + amount > supplyCap) {
      revert PSMErrors.SupplyCapReached();
    }
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
  function updateFees(uint256 _mintFeeBps, uint256 _redeemFeeBps) external onlyOwner {
    _updateFees(_mintFeeBps, _redeemFeeBps);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function updateFeeDistributor(
    address _newFeeDistributor
  ) external onlyOwner {
    _updateFeeDistributor(_newFeeDistributor);
  }

  /// @inheritdoc IPegStabilityModuleYield
  function toCollateralAmount(
    uint256 _amount
  ) public view returns (uint256) {
    return (_amount * 1e18) / getAssetsFromShares();
  }

  /// @inheritdoc IPegStabilityModuleYield
  function toCollateralAmountWithFee(uint256 _amount, uint256 _fee) public view returns (uint256) {
    return (toCollateralAmount(_amount) * (MAX_FEE_BPS + _fee)) / MAX_FEE_BPS;
  }

  /// @inheritdoc IPegStabilityModuleYield
  function toCollateralAmountWithFeeInverse(uint256 _amount, uint256 _fee) public view returns (uint256) {
    return (toCollateralAmount(_amount) * (MAX_FEE_BPS - _fee)) / MAX_FEE_BPS;
  }

  /// @inheritdoc IPegStabilityModuleYield
  function feesCollected() public view returns (uint256) {
    return collateral.balanceOf(address(this)) - toCollateralAmount(debt);
  }

  /**
   * @notice Calculates the value of assets per share in the collateral pool.
   * @dev Uses total assets and total supply from the collateral to compute the ratio.
   * @return The asset value per share in 18 decimal precision.
   */
  function getAssetsFromShares() public view returns (uint256) {
    return (collateral.totalAssets() * 1e18) / collateral.totalSupply();
  }

  /**
   * @notice Ensures that a given address is not the zero address.
   * @dev Reverts with `PSMErrors.NotZeroAddress` if the provided address is zero.
   * @param address_ The address to check.
   */
  function ensureNonZeroAddress(
    address address_
  ) internal pure {
    if (address_ == address(0)) {
      revert PSMErrors.NotZeroAddress();
    }
  }

  /**
   * @notice Ensures that a given value is non-zero.
   * @dev Reverts with `PSMErrors.NotZeroValue` if the provided value is zero.
   * @param value_ The value to check.
   */
  function ensureNonZeroValue(
    uint256 value_
  ) internal pure {
    if (value_ == 0) {
      revert PSMErrors.NotZeroValue();
    }
  }

  function _updateCaps(uint256 _supplyCap, uint256 _debtCap) internal {
    uint256 oldSupplyCap = supplyCap;
    uint256 olsDebtCap = debtCap;

    supplyCap = _supplyCap;
    debtCap = _debtCap;

    emit PSMEventsLib.SupplyCapUpdated(_supplyCap, _debtCap, oldSupplyCap, olsDebtCap, msg.sender);
  }

  /**
   * @notice Updates the fee destination
   * @param _newFeeDistributor the new fee destination
   */
  function _updateFeeDistributor(
    address _newFeeDistributor
  ) internal {
    address oldFeeDestination = feeDistributor;
    feeDistributor = _newFeeDistributor;
    emit PSMEventsLib.FeeDestinationUpdated(_newFeeDistributor, oldFeeDestination, msg.sender);
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

  /**
   * @notice Transfers yield from the collateral to the fee distributor if yield exceeds debt.
   * @dev Computes yield based on the collateral balance and transfers it to the fee distributor if
   *      the current value of collateral exceeds the outstanding debt.
   *      Uses `safeTransfer` to ensure secure transfer of assets.
   */
  function transferYieldToFeeDistributor() public {
    uint256 bal = collateral.balanceOf(address(this));
    uint256 val = ((bal * getAssetsFromShares()) / 1e18);
    if (val > debt) {
      uint256 yield = ((val - debt) * 1e18) / getAssetsFromShares();
      collateral.safeTransfer(feeDistributor, yield);
    }
  }
}
