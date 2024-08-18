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
 * @title A Direct Deposit Module that sends the newly minted ZAI to a hub on a layer 2 via an optimism bridge
 * @dev Assumes that the destination on the OP chain is a valid contract with proper controls.
 * @author maha.xyz
 * @notice A direct deposit module that sends tokens to an OP chain
 */
contract DDOptimismHub is Initializable, DDBase {
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
    zai.transferFrom(msg.sender, address(this), wad);
    // TODO: bridge the tokens to the destination contract via the optimism bridge
  }

  /// @inheritdoc IDDPool
  /// @dev Any withdrawn amount will be held in the contract
  function withdraw(uint256 wad) external override onlyHub {
    bridged -= wad;
    zai.transfer(msg.sender, wad);
  }

  // https://github.com/base-org/guides/blob/main/bridge/native/README.md
  function proveBridgeWithdrawal() external {
    // todo
  }

  // https://github.com/base-org/guides/blob/main/bridge/native/README.md
  function finalizeBridgeWithdrawal() external {
    // todo
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
    return bridged + zai.balanceOf(address(this));
  }

  /// @inheritdoc IDDPool
  function maxDeposit() external pure returns (uint256) {
    return type(uint256).max;
  }

  /// @inheritdoc IDDPool
  function maxWithdraw() external view returns (uint256) {
    return zai.balanceOf(address(this));
  }

  /// @inheritdoc IDDPool
  function redeemable() external view returns (address) {
    return address(this);
  }
}
