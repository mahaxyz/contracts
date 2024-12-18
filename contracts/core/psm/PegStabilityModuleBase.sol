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
import {IPegStabilityModule} from "../../interfaces/core/IPegStabilityModule.sol";

import {PSMErrors} from "../../interfaces/errors/PSMErrors.sol";
import {PSMEventsLib} from "../../interfaces/events/PSMEventsLib.sol";
import {AccessControlEnumerableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Peg Stability Module
 * @author maha.xyz
 * @notice Used to mint ZAI with collateral at a pre-defined rate
 * @dev https://docs.maha.xyz/mechanics/peg-mechanics/peg-stablility-module-psm
 */
abstract contract PegStabilityModuleBase is
  AccessControlEnumerableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  IPegStabilityModule
{
  using SafeERC20 for IERC20;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");

  /// @inheritdoc IPegStabilityModule
  IStablecoin public zai;

  /// @inheritdoc IPegStabilityModule
  IERC20 public collateral;

  /// @inheritdoc IPegStabilityModule
  uint256 public supplyCap;

  /// @inheritdoc IPegStabilityModule
  uint256 public debtCap;

  /// @inheritdoc IPegStabilityModule
  uint256 public debt;

  /// @inheritdoc IPegStabilityModule
  uint256 public mintFeeBps;

  /// @inheritdoc IPegStabilityModule
  uint256 public redeemFeeBps;

  /// @inheritdoc IPegStabilityModule
  address public feeDestination;

  /// @inheritdoc IPegStabilityModule
  uint256 public immutable MAX_FEE_BPS = 10_000;

  function __PegStabilityModule_init(
    address _zai,
    address _collateral,
    address _governance,
    uint256 _supplyCap,
    uint256 _debtCap,
    uint256 _mintFeeBps,
    uint256 _redeemFeeBps,
    address _feeDestination
  ) internal {
    __Pausable_init();
    __AccessControlEnumerable_init();
    __ReentrancyGuard_init();

    zai = IStablecoin(_zai);
    collateral = IERC20(_collateral);

    if (_zai == address(0) || _collateral == address(0) || _governance == address(0) || _feeDestination == address(0)) {
      revert PSMErrors.NotZeroAddress();
    }

    if (_supplyCap == 0 || _debtCap == 0) {
      revert PSMErrors.NotZeroValue();
    }

    _grantRole(DEFAULT_ADMIN_ROLE, _governance);
    _grantRole(PAUSER_ROLE, _governance);
    _grantRole(FEE_COLLECTOR_ROLE, _governance);

    _updateFees(_mintFeeBps, _redeemFeeBps);
    _updateCaps(_supplyCap, _debtCap);
    _updateFeeDestination(_feeDestination);
  }

  /// @inheritdoc IPegStabilityModule
  function mint(address dest, uint256 shares) external nonReentrant whenNotPaused {
    uint256 amount = toCollateralAmountWithFee(shares, mintFeeBps);

    if (amount == 0) revert PSMErrors.NotZeroValue();
    if (shares == 0) revert PSMErrors.NotZeroValue();

    if (collateral.balanceOf(address(this)) + amount > supplyCap) revert PSMErrors.SupplyCapReached();
    if (debt + shares > debtCap) revert PSMErrors.DebtCapReached();

    collateral.safeTransferFrom(msg.sender, address(this), amount);
    zai.mint(dest, shares);

    debt += shares;
    emit PSMEventsLib.Mint(dest, shares, amount, debt, supplyCap, msg.sender);
  }

  /// @inheritdoc IPegStabilityModule
  function redeem(address dest, uint256 shares) external nonReentrant whenNotPaused {
    uint256 amount = toCollateralAmountWithFeeInverse(shares, redeemFeeBps);

    if (amount == 0) revert PSMErrors.NotZeroValue();
    if (shares == 0) revert PSMErrors.NotZeroValue();

    zai.transferFrom(msg.sender, address(this), shares);
    zai.burn(address(this), shares);
    collateral.safeTransfer(dest, amount);

    debt -= shares;
    emit PSMEventsLib.Redeem(dest, shares, amount, debt, supplyCap, msg.sender);
  }

  /// @notice Returns the current rate of ZAI/Collateral
  function rate() public view virtual returns (uint256);

  /// @notice Collects fees from the collateral pool
  function sweepFees() external whenNotPaused onlyRole(FEE_COLLECTOR_ROLE) {
    collateral.safeTransfer(feeDestination, feesCollected());
  }

  /// @notice Pauses the contract
  function togglePause() external onlyRole(PAUSER_ROLE) {
    if (paused()) _unpause();
    else _pause();
  }

  /// @inheritdoc IPegStabilityModule
  function updateCaps(uint256 _supplyCap, uint256 _debtCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _updateCaps(_supplyCap, _debtCap);
  }

  /// @inheritdoc IPegStabilityModule
  function updateFees(uint256 _mintFeeBps, uint256 _redeemFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _updateFees(_mintFeeBps, _redeemFeeBps);
  }

  /// @inheritdoc IPegStabilityModule
  function updateFeeDestination(address _feeDestination) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _updateFeeDestination(_feeDestination);
  }

  /// @inheritdoc IPegStabilityModule
  function toCollateralAmount(uint256 _shares) public view returns (uint256) {
    return (_shares * rate()) / 1e18;
  }

  /// @inheritdoc IPegStabilityModule
  function mintAmountIn(uint256 amountAssetsIn) external view override returns (uint256 shares) {
    shares = (amountAssetsIn * 1e18 * MAX_FEE_BPS) / (MAX_FEE_BPS + mintFeeBps) / rate();
  }

  /// @inheritdoc IPegStabilityModule
  function redeemAmountOut(uint256 amountAssetsOut) external view override returns (uint256 shares) {
    shares = (amountAssetsOut * 1e18 * MAX_FEE_BPS) / (MAX_FEE_BPS - redeemFeeBps) / rate();
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
  function feesCollected() public view virtual returns (uint256);

  function _updateCaps(uint256 _supplyCap, uint256 _debtCap) internal {
    uint256 oldSupplyCap = supplyCap;
    uint256 olsDebtCap = debtCap;

    supplyCap = _supplyCap;
    debtCap = _debtCap;

    emit PSMEventsLib.SupplyCapUpdated(_supplyCap, _debtCap, oldSupplyCap, olsDebtCap, msg.sender);
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
