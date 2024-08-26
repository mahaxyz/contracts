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

import {DDBase, IDDPool} from "./DDBase.sol";

import {AccessControlEnumerableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title A private loan on Morpho Blue
/// @author maha.xyz
/// @notice Uses
contract DDPrivateMorphoLoan is ERC20Upgradeable, AccessControlEnumerableUpgradeable, DDBase {
  IERC20 public collateral;
  bytes32 public morphoMarketId;

  uint256 public borrowed;
  uint256 public supplied;
  address public morpho;

  bytes32 public immutable BORROWER_ROLE = keccak256("BORROWER_ROLE");
  // bytes32 public immutable EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

  function initialize(address _hub, address _admin, address _zai, address _collateral) external reinitializer(1) {
    __DDBBase_init(_zai, _hub);
    __AccessControlEnumerable_init();

    collateral = IERC20(_collateral);

    require(_hub != address(0), "DDPrivateLoan/zero-address");
    require(_zai != address(0), "DDPrivateLoan/zero-address");
    require(_admin != address(0), "DDPrivateLoan/zero-address");
    require(_collateral != address(0), "DDPrivateLoan/zero-address");

    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  /// @inheritdoc IDDPool
  function deposit(uint256 wad) external override onlyHub {
    zai.transferFrom(msg.sender, me, wad);
  }

  /// https://github.com/morpho-org/metamorpho/blob/fcf3c41d9c113514c9af0bbf6298e88a1060b220/src/MetaMorpho.sol#L557
  /// @inheritdoc IDDPool
  function withdraw(uint256 wad) external override onlyHub {
    // nothing
  }

  /// @inheritdoc IDDPool
  function preDebtChange() external override {
    // nothing
  }

  /// @inheritdoc IDDPool
  function postDebtChange() external override {
    // nothing
  }

  /// @dev Once a morpho market is created with the loan as collateral, we execute this function
  /// @param id The morpho market
  function setMorphoId(bytes32 id) external onlyRole(DEFAULT_ADMIN_ROLE) {
    morphoMarketId = id;
  }

  function supplyCollateral(uint256 collateralAmount) external onlyRole(BORROWER_ROLE) {
    collateral.transferFrom(msg.sender, me, collateralAmount);
    _mint(msg.sender, collateralAmount);
  }

  function withdrawCollateral(uint256 collateralAmount) external onlyRole(BORROWER_ROLE) {
    collateral.transfer(msg.sender, collateralAmount);
    _burn(msg.sender, collateralAmount);
  }

  /// @inheritdoc IDDPool
  function assetBalance() external view returns (uint256) {
    return zai.balanceOf(me);
  }

  /// @inheritdoc IDDPool
  function maxDeposit() external pure returns (uint256) {
    return type(uint256).max;
  }

  /// @inheritdoc IDDPool
  function maxWithdraw() external view returns (uint256) {
    return zai.balanceOf(me);
  }

  /// @inheritdoc IDDPool
  function redeemable() external view returns (address) {
    return me;
  }

  function _update(address from, address to, uint256 value) internal override {
    require(hasRole(BORROWER_ROLE, from) || from == morpho, "not authorized");
    super._update(from, to, value);
  }
}
