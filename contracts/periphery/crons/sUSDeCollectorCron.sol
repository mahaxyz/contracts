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

import {OwnableUpgradeable, Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {PSMErrors} from "../../interfaces/errors/PSMErrors.sol";
import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";
import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SUSDECollectorCron
 * @notice A contract that manages revenue distribution through USDC transfers, using Stargate for cross-chain messaging
 *         and optionally performing swaps via the ODOS router.
 * @dev The contract is upgradeable and inherits `Ownable2StepUpgradeable`. It supports setting an ODOS router,
 *      defining sUSDz and USDC tokens, and has functions for swapping and cross-chain revenue distribution.
 */
contract SUSDECollectorCron is Ownable2StepUpgradeable {
  using SafeERC20 for IERC20;

  /// @notice Address of the ODOS router for executing swaps.
  address public odos;

  /// @notice Address of the sUSDz token contract.
  address public sUSDz;

  /// @notice Interface for the USDC token contract.
  IERC20 public usdc;

  /// @notice Emitted when revenue is distributed to a receiver.
  /// @param receiver The address that receives the distributed revenue.
  /// @param amount The amount of revenue distributed in USDC.
  event RevenueDistributed(address indexed receiver, uint256 indexed amount);

  /**
   * @notice Initializes the contract with addresses for the ODOS router, sUSDz, and USDC tokens.
   * @dev Ensures non-zero addresses for essential contracts, initializes the owner, and sets the ODOS router.
   * @param _odos Address of the ODOS router.
   * @param _sUsde Address of the sUSDz token contract.
   * @param _usdc Address of the USDC token contract.
   */
  function initialize(
    address _odos,
    address _sUsde,
    address _usdc
  ) public initializer {
    ensureNonzeroAddress(_sUsde);
    ensureNonzeroAddress(_usdc);
    __Ownable_init(msg.sender);
    sUSDz = _sUsde;
    usdc = IERC20(_usdc);
    setOdos(_odos);
  }

  /**
   * @notice Executes a swap from sUSDz to USDC via the ODOS router.
   * @dev This function can only be called by the contract owner.
   * @param data Encoded data required by the ODOS router for executing the swap.
   * @param amount How much sUSDe you want ODOS router to swap
   */
  function swapToUSDC(
    bytes calldata data,
    uint256 amount
  ) external payable onlyOwner {
    _swapSUSDzToUSDC(data, amount);
  }

  /**
   * @notice Sets the address for the ODOS router.
   * @dev Can only be called by the contract owner.
   * @param _odos New address of the ODOS router.
   */
  function setOdos(address _odos) public onlyOwner {
    odos = _odos;
  }

  /**
   * @notice Distributes revenue by transferring 50% of the contract's current USDC balance.
   *         If `_odos` calldata is provided, it performs a swap from sUSDz to USDC before distribution.
   * @dev Calls `_swapSUSDzToUSDC` if `odos` calldata is provided. Then calculates 50% of the USDC balance
   *      and transfers it to the sUSDz contract, subsequently calling `_distributeRevenue`.
   * @param _stargateUSDCPool The address of the Stargate USDC pool.
   * @param _destinationEndPoint The endpoint identifier for the Stargate pool.
   * @param _amount How much sUSDe you want ODOS router to swap
   * @param _receiver The address that will receive the distributed revenue.
   * @param _refundAddress The address to receive any excess funds from fees etc. on the source chain.
   * @param _odos Optional calldata to perform a swap from sUSDz to USDC if provided.
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
    _distributeRevenue(
      _stargateUSDCPool,
      _destinationEndPoint,
      balanceUSDC - amount,
      _receiver,
      _refundAddress
    );
  }

  /**
   * @notice Internal function to swap sUSDz to USDC by calling the `odos` contract.
   * @dev Executes a low-level call to `odos` using the provided calldata.
   *      Reverts if the `odos` call fails.
   * @param data Encoded call data required by the `odos` contract to perform the swap.
   * @param _amount How much sUSDe you want ODOS router to swap
   */
  function _swapSUSDzToUSDC(bytes calldata data, uint256 _amount) internal {
    IERC20(sUSDz).approve(odos, _amount);
    (bool ok, ) = odos.call{value: msg.value}(data);
    require(ok, "odos call failed");
  }

  /**
   * @notice Internal function to facilitate the distribution of revenue using Stargate's cross-chain messaging.
   * @dev Prepares parameters, calculates fees, and performs the token send operation using the Stargate protocol.
   * @param _stargate The address of the Stargate contract to be used for sending tokens.
   * @param _dstEid The destination endpoint identifier for cross-chain transfer.
   * @param _amount The amount of tokens to send.
   * @param _receiver The recipient address on the destination chain.
   * @param _refundAddress The address to receive any excess funds.
   */
  function _distributeRevenue(
    address _stargate,
    uint32 _dstEid,
    uint256 _amount,
    address _receiver,
    address _refundAddress
  ) internal {
    (
      uint256 valueToSend,
      SendParam memory sendParam,
      MessagingFee memory messagingFee
    ) = prepareTakeTaxi(_stargate, _dstEid, _amount, _receiver);
    IStargate(_stargate).sendToken{value: valueToSend}(
      sendParam,
      messagingFee,
      _refundAddress
    );

    emit RevenueDistributed(_receiver, _amount);
  }

  /**
   * @notice Prepares parameters and calculates fees for sending tokens using Stargate's cross-chain messaging.
   * @dev Constructs the necessary parameters and estimates messaging fees for the cross-chain transaction.
   *      Adjusts the `minAmountLD` based on the quoted amount to be received on the destination.
   * @param _stargate The address of the Stargate contract to be used for sending tokens.
   * @param _dstEid The destination chain ID where the tokens will be sent.
   * @param _amount The amount of tokens to send, denominated in local decimals (LD).
   * @param _receiver The address on the destination chain to receive the tokens.
   * @return valueToSend The total native fee required to send the transaction, including the amount if Stargate is on a native chain.
   * @return sendParam The `SendParam` structure containing all details needed for the cross-chain transaction.
   * @return messagingFee The `MessagingFee` structure containing the estimated native fees for the transaction.
   */
  function prepareTakeTaxi(
    address _stargate,
    uint32 _dstEid,
    uint256 _amount,
    address _receiver
  )
    internal
    view
    returns (
      uint256 valueToSend,
      SendParam memory sendParam,
      MessagingFee memory messagingFee
    )
  {
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

    (, , OFTReceipt memory receipt) = stargate.quoteOFT(sendParam);
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
  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  /**
   * @notice Ensures that a given address is not the zero address.
   * @dev Reverts with `NotZeroAddress` error if `address_` is the zero address.
   *      Useful for validating that essential addresses (e.g., contract or wallet addresses) are non-zero.
   * @param address_ The address to be checked.
   */
  function ensureNonzeroAddress(address address_) internal pure {
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
  function calculatePercentage(
    uint256 amount,
    uint256 bps
  ) internal pure returns (uint256) {
    require((amount * bps) >= 10_000, "amount * bps > 10_000");
    return (amount * bps) / 10_000;
  }

  /**
   * @notice Refunds the specified token balance held by the contract to the caller.
   * @dev Only callable by owner of the contract
   * @param token The ERC20 token to be refunded.
   */
  function refund(IERC20 token) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }
}
