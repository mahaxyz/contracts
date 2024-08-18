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

import {DDBase, IDDPool} from "../DDBase.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title A Direct Deposit Module that sends the newly minted ZAI to a hub on a layer 2 via a L2 bridge
 * @dev Assumes that the destination on the L2 chain is a valid contract with proper controls.
 * @author maha.xyz
 * @notice A direct deposit module that sends ZAI to an L2 chain
 */
abstract contract DDBaseL2 is Initializable, DDBase {
  address public destinationL2;
  address public bridgeL2;
  uint256 public bridged;

  function initialize(address _hub, address _zai, address _destinationL2, address _bridgeL2) external reinitializer(1) {
    __DDBBase_init(_zai, _hub);

    destinationL2 = _destinationL2;
    bridgeL2 = _bridgeL2;

    require(_hub != address(0), "DDOptimismTransfer/zero-address");
    require(_zai != address(0), "DDOptimismTransfer/zero-address");
    require(_destinationL2 != address(0), "DDOptimismTransfer/zero-address");
    require(_bridgeL2 != address(0), "DDOptimismTransfer/zero-address");

    zai.approve(bridgeL2, type(uint256).max);
  }

  /// @inheritdoc IDDPool
  function deposit(uint256 wad) external override onlyHub {
    bridged += wad;
    zai.transferFrom(msg.sender, me, wad);
    _depositToBridge(destinationL2, wad);
  }

  /// @inheritdoc IDDPool
  /// @dev Any withdrawn amount will be held in the contract
  function withdraw(uint256 wad) external override onlyHub {
    bridged -= wad;
    zai.transfer(msg.sender, wad);
  }

  /// @inheritdoc IDDPool
  function preDebtChange() external override {
    // nothing
  }

  /// @inheritdoc IDDPool
  function postDebtChange() external override {
    // nothing
  }

  /// @inheritdoc IDDPool
  function assetBalance() external view returns (uint256) {
    return bridged + zai.balanceOf(me);
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

  function _depositToBridge(address to, uint256 amount) internal virtual;
}
