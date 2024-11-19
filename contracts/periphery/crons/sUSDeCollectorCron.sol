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

import {PSMErrors} from "../../interfaces/errors/PSMErrors.sol";

import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {
  Ownable2StepUpgradeable,
  OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";

/**
 * @title SUSDECollectorCron
 * @notice Manages revenue distribution using USDC transfers, cross-chain messaging via Stargate,
 *         and optional token swaps via the ODOS router.
 * @dev This is an upgradeable contract that inherits `Ownable2StepUpgradeable`. It supports defining
 *      sUSDz, USDC, and sUSDe tokens, and includes functionality for revenue distribution and swaps.
 */
contract SUSDECollectorCron is Ownable2StepUpgradeable {
  using SafeERC20 for IERC20;

  /// @notice Address of the ODOS router for executing token swaps.
  address public odos;

  /// @notice Address of the sUSDz token contract.
  address public sUSDz;

  /// @notice Interface for the USDC token contract.
  IERC20 public usdc;

  /// @notice Interface for the sUSDe token contract.
  IERC4626 public sUSDe;

  /**
   * @notice Emitted when revenue is distributed to a specific receiver.
   * @param receiver The address of the revenue recipient.
   * @param amount The amount of revenue distributed in USDC.
   */
  event RevenueDistributed(address indexed receiver, uint256 indexed amount);

  /**
   * @notice Initializes the contract with essential addresses and sets the ODOS router.
   * @dev This function can only be called once, during deployment.
   * @param _odos The address of the ODOS router for token swaps.
   * @param _sUSDz The address of the sUSDz token contract.
   * @param _usdc The address of the USDC token contract.
   * @param _sUSDe The address of the sUSDe token contract.
   */
  function initialize(address _odos, address _sUSDz, address _usdc, address _sUSDe) public initializer {
    ensureNonzeroAddress(_sUSDz);
    ensureNonzeroAddress(_usdc);
    ensureNonzeroAddress(_sUSDe);
    __Ownable_init(msg.sender);
    sUSDz = _sUSDz;
    usdc = IERC20(_usdc);
    sUSDe = IERC4626(_sUSDe);
    setOdos(_odos);
  }

  /**
   * @notice Executes a swap from sUSDz to USDC using the ODOS router.
   * @dev Only callable by the owner.
   * @param data Encoded data required by the ODOS router for the swap.
   * @param amount The amount of sUSDe tokens to swap via the ODOS router.
   */
  function swapToUSDC(bytes calldata data, uint256 amount) external payable onlyOwner {
    _swapSUSDzToUSDC(data, amount);
  }

  /**
   * @notice Updates the address of the ODOS router.
   * @dev Only callable by the owner.
   * @param _odos The new address of the ODOS router.
   */
  function setOdos(
    address _odos
  ) public onlyOwner {
    odos = _odos;
  }

  /**
   * @notice Distributes revenue by transferring 50% of USDC balance and optionally performing a swap.
   * @dev Handles cross-chain messaging via Stargate. Calls `_swapSUSDzToUSDC` if `_odos` calldata is provided.
   * @param _stargateUSDCPool Address of the Stargate USDC pool.
   * @param _destinationEndPoint Destination endpoint for Stargate.
   * @param _amount Amount of sUSDe tokens to swap using ODOS router, if applicable.
   * @param _receiver The address receiving distributed revenue.
   * @param _refundAddress Address to receive any excess funds from fees.
   * @param _odos Optional calldata for a swap operation via the ODOS router.
   */
  function distributeRevenue(
    address _stargateUSDCPool,
    uint32 _destinationEndPoint,
    uint256 _amount,
    address _receiver,
    address _refundAddress,
    bytes calldata _odos
  ) public payable onlyOwner {
    ensureNonzeroAddress(_stargateUSDCPool);
    ensureNonzeroAddress(_receiver);
    if (_odos.length > 0) {
      _swapSUSDzToUSDC(_odos, _amount);
    }
    uint256 balanceUSDC = IERC20(usdc).balanceOf(address(this));
    require(balanceUSDC > 0, "Zero balance");
    uint256 amount = calculatePercentage(balanceUSDC, 5000); // 50% of balance to send for buyback/burn on base chain.
    // Sending 50% revenue to sUSDz stakers contract.
    IERC20(usdc).safeTransfer(sUSDz, amount);
    _distributeRevenue(_stargateUSDCPool, _destinationEndPoint, balanceUSDC - amount, _receiver, _refundAddress);
  }

  /**
   * @notice Swaps sUSDz to USDC using the ODOS router.
   * @dev Internal function for executing a swap with the provided calldata.
   * @param data Encoded call data for the ODOS router.
   * @param _amount The amount of sUSDe tokens to swap.
   */
  function _swapSUSDzToUSDC(bytes calldata data, uint256 _amount) internal {
    sUSDe.approve(odos, _amount);
    (bool ok,) = odos.call{value: msg.value}(data);
    require(ok, "odos call failed");
  }

  /**
   * @notice Internal function to distribute revenue using Stargate cross-chain messaging.
   * @dev Uses Stargate for token transfers and emits a RevenueDistributed event.
   * @param _stargate Address of the Stargate contract.
   * @param _dstEid Destination chain ID for the cross-chain transfer.
   * @param _amount Amount of tokens to send.
   * @param _receiver Recipient address on the destination chain.
   * @param _refundAddress Address for excess funds refund.
   */
  function _distributeRevenue(
    address _stargate,
    uint32 _dstEid,
    uint256 _amount,
    address _receiver,
    address _refundAddress
  ) internal {
    (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
      prepareTakeTaxi(_stargate, _dstEid, _amount, _receiver);
    IStargate(_stargate).sendToken{value: valueToSend}(sendParam, messagingFee, _refundAddress);

    emit RevenueDistributed(_receiver, _amount);
  }

  /**
   * @notice Prepares parameters for sending tokens using Stargate.
   * @dev Estimates fees and constructs parameters for cross-chain messaging.
   * @param _stargate Address of the Stargate contract.
   * @param _dstEid Destination chain ID.
   * @param _amount Amount of tokens to send.
   * @param _receiver Recipient address on the destination chain.
   * @return valueToSend Total native fee for the transaction.
   * @return sendParam Parameters required for Stargate's `sendToken` method.
   * @return messagingFee Estimated fees for the cross-chain transaction.
   */
  function prepareTakeTaxi(
    address _stargate,
    uint32 _dstEid,
    uint256 _amount,
    address _receiver
  ) internal view returns (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) {
    sendParam = SendParam({
      dstEid: _dstEid,
      to: addressToBytes32(_receiver),
      amountLD: _amount,
      minAmountLD: _amount,
      extraOptions: new bytes(0),
      composeMsg: new bytes(0),
      oftCmd: ""
    });

    IStargate stargate = IStargate(_stargate);

    (,, OFTReceipt memory receipt) = stargate.quoteOFT(sendParam);
    sendParam.minAmountLD = receipt.amountReceivedLD;

    messagingFee = stargate.quoteSend(sendParam, false);
    valueToSend = messagingFee.nativeFee;

    if (stargate.token() == address(0x0)) {
      valueToSend += sendParam.amountLD;
    }
  }

  /**
   * @notice Converts an address to a bytes32 format.
   * @dev This is necessary for cross-chain transfers where addresses need to be converted to bytes32.
   * @param _addr The address to convert.
   * @return The converted bytes32 representation of the address.
   */
  function addressToBytes32(
    address _addr
  ) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  /**
   * @notice Ensures that a given address is not the zero address.
   * @dev Reverts with `NotZeroAddress` error if `address_` is the zero address.
   *      Useful for validating that essential addresses (e.g., contract or wallet addresses) are non-zero.
   * @param address_ The address to be checked.
   */
  function ensureNonzeroAddress(
    address address_
  ) internal pure {
    if (address_ == address(0)) {
      revert PSMErrors.NotZeroAddress();
    }
  }

  /**
   * @notice Calculates a percentage of a given `amount` based on basis points (bps).
   * @dev The calculation uses basis points, where 10,000 bps = 100%.
   *      Reverts if `amount * bps` is less than 10,000 to prevent overflow issues.
   * @param amount The initial amount to calculate the percentage from.
   * @param bps The basis points (bps) representing the percentage (e.g., 5000 for 50%).
   * @return The calculated percentage of `amount` based on `bps`.
   */
  function calculatePercentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    require((amount * bps) >= 10_000, "amount * bps > 10_000");
    return (amount * bps) / 10_000;
  }

  /**
   * @notice Refunds the specified token balance held by the contract to the caller.
   * @dev Only callable by owner of the contract
   * @param token The ERC20 token to be refunded.
   */
  function refund(
    IERC20 token
  ) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }
}
