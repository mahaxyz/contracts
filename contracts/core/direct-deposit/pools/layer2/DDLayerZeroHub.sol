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

import {IOFT, MessagingFee, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title A Direct Deposit Module that sends the newly minted ZAI to a hub on a layer 2 via a L2 bridge
 * @dev Assumes that the destination on the L2 chain is a valid contract with proper controls.
 * @author maha.xyz
 * @notice A direct deposit module that sends ZAI to an L2 chain
 */
contract DDLayerZeroHub is Initializable, DDBase {
  bytes32 public destinationL2;
  IOFT public oftAdapter;
  uint256 public bridged;
  uint32 public dstEid;
  address internal ethRefundAddress;

  function initialize(
    address _hub,
    address _zai,
    bytes32 _destinationL2,
    address _oftAdapter,
    uint32 _dstEid
  ) external reinitializer(1) {
    __DDBBase_init(_zai, _hub);

    destinationL2 = _destinationL2;
    dstEid = _dstEid;
    oftAdapter = IOFT(_oftAdapter);

    require(_hub != address(0), "DDLayerZeroHub/zero-address");
    require(_zai != address(0), "DDLayerZeroHub/zero-address");
    require(_destinationL2 != bytes32(0), "DDLayerZeroHub/zero-address");
    require(_oftAdapter != address(0), "DDLayerZeroHub/zero-address");

    zai.approve(_oftAdapter, type(uint256).max);
  }

  receive() external payable {
    // nothing
  }

  /// @inheritdoc IDDPool
  function deposit(uint256 wad) external override onlyHub {
    bridged += wad;
    zai.transferFrom(msg.sender, me, wad);
  }

  function depositToBridge(uint256 wad) external payable {
    SendParam memory param = SendParam({
      dstEid: dstEid,
      to: bytes32(uint256(destinationL2)),
      amountLD: wad,
      minAmountLD: wad,
      extraOptions: "",
      composeMsg: "",
      oftCmd: ""
    });
    MessagingFee memory fee = MessagingFee({nativeFee: msg.value, lzTokenFee: 0});
    oftAdapter.send{value: msg.value}(param, fee, address(this));
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
    return bridged;
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
}
