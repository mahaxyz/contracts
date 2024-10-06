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

import {IStargate} from "../../interfaces/periphery/layerzero/IStargate.sol";
import {IOFT, MessagingFee, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

import {IL2DepositCollateralL0} from "../../interfaces/periphery/layerzero/IL2DepositCollateralL0.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract L2RestakingSweeperCron is OwnableUpgradeable {
  address public gelatoooooo;
  address public usdc;
  uint256 public limit;
  IL2DepositCollateralL0 public depositCollateralL0;

  function initialize(
    address _gelatoooooo,
    address _usdc,
    uint256 _limit,
    address _depositCollateralL0,
    address _governance
  ) public reinitializer(1) {
    __Ownable_init(msg.sender);

    gelatoooooo = _gelatoooooo;
    usdc = _usdc;
    limit = _limit;
    depositCollateralL0 = IL2DepositCollateralL0(_depositCollateralL0);

    _transferOwnership(_governance);
  }

  receive() external payable {
    // nothing
  }

  function setSweepLimit(uint256 _limit) public onlyOwner {
    limit = _limit;
  }

  function setGelatoooooo(address _gelatoooooo) public onlyOwner {
    gelatoooooo = _gelatoooooo;
  }

  function usdcToSweep() public view returns (uint256) {
    return IERC20(usdc).balanceOf(address(depositCollateralL0));
  }

  function feeEthToTransfer() public view returns (uint256) {
    uint256 amount = IERC20(usdc).balanceOf(address(depositCollateralL0));

    SendParam memory _sendParam = SendParam({
      dstEid: 30_101, // Destination endpoint ID. 30101 is the mainnet endpoint.
      to: depositCollateralL0.bridgeTargetAddress(), // Recipient address.
      amountLD: amount, // Amount to send in local decimals.
      minAmountLD: amount * (1e18 - depositCollateralL0.slippage()) / 1e18, //  Minimum amount to send in local
        // decimals.
      extraOptions: "", // Additional options supplied by the caller to be used in the LayerZero message.
      composeMsg: "", // The composed message for the send() operation.
      oftCmd: "" // The OFT command to be executed, unused in default OFT implementations.
    });

    IStargate stargate = depositCollateralL0.stargate();
    MessagingFee memory _fee = stargate.quoteSend(_sendParam, false);

    return _fee.nativeFee;
  }

  function shouldExecute() public view returns (bool) {
    return usdcToSweep() >= limit;
  }

  function execute() public payable {
    require(msg.sender == owner() || msg.sender == gelatoooooo, "who dis?");
    uint256 amount = IERC20(usdc).balanceOf(address(depositCollateralL0));
    depositCollateralL0.sweep{value: feeEthToTransfer()}(amount);
  }

  function refundETH() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}
