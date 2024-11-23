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

import {IMultiStakingRewardsERC4626} from "../../interfaces/core/IMultiStakingRewardsERC4626.sol";
import {PSMErrors} from "../../interfaces/errors/PSMErrors.sol";
import {IStargate} from "../../interfaces/periphery/layerzero/IStargate.sol";
import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title sUSDeCollectorCron
 * @notice A contract that manages revenue distribution through USDC transfers, using Stargate for cross-chain messaging
 *         and optionally performing swaps via the ODOS router.
 * @dev The contract is upgradeable and inherits `Ownable2StepUpgradeable`. It supports setting an ODOS router,
 *      defining sZAI and USDC tokens, and has functions for swapping and cross-chain revenue distribution.
 */
contract sUSDeCollectorCron is AccessControlEnumerable {
  using SafeERC20 for IERC20;

  bytes32 public immutable EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

  /// @notice Address of the ODOS router for executing swaps.
  address public odos;

  /// @notice Address of the sZAI token contract.
  IMultiStakingRewardsERC4626 public sZAI;

  /// @notice Interface for the USDC token contract.
  IERC20 public usdc;

  /// @notice Interface for the sUSDe token contract.
  IERC20 public sUSDe;

  /// @notice Emitted when revenue is distributed to a receiver.
  /// @param receiver The address that receives the distributed revenue.
  /// @param amount The amount of revenue distributed in USDC.
  event RevenueDistributed(address indexed receiver, uint256 indexed amount);

  /**
   * @notice Initializes the contract with addresses for the ODOS router, sZAI, and USDC tokens.
   * @dev Ensures non-zero addresses for essential contracts, initializes the owner, and sets the ODOS router.
   * @param _odos Address of the ODOS router.
   * @param _sZAI Address of the sZAI token contract.
   * @param _usdc Address of the USDC token contract.
   */
  constructor(address _odos, address _sZAI, address _sUSDe, address _usdc) {
    ensureNonzeroAddress(_sZAI);
    ensureNonzeroAddress(_usdc);

    sZAI = IMultiStakingRewardsERC4626(_sZAI);
    sUSDe = IERC20(_sUSDe);
    usdc = IERC20(_usdc);
    odos = _odos;

    sUSDe.approve(odos, type(uint256).max);
    usdc.approve(address(sZAI), type(uint256).max);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(EXECUTOR_ROLE, msg.sender);
  }

  /**
   * @notice Distributes revenue by transferring 50% of the contract's current USDC balance.
   *         If `_odos` calldata is provided, it performs a swap from sZAI to USDC before distribution.
   * @dev Calls `_swapsUSDeToUSDC` if `odos` calldata is provided. Then calculates 50% of the USDC balance
   *      and transfers it to the sZAI contract, subsequently calling `_distributeRevenue`.
   * @param _stargateUSDCPool The address of the Stargate USDC pool.
   * @param _destinationEndPoint The endpoint identifier for the Stargate pool.
   * @param _receiver The address that will receive the distributed revenue.
   * @param _refundAddress The address to receive any excess funds from fees etc. on the source chain.
   * @param _odos Optional calldata to perform a swap from sZAI to USDC if provided.
   */
  function distributeRevenue(
    address _stargateUSDCPool,
    uint32 _destinationEndPoint,
    address _receiver,
    address _refundAddress,
    bytes calldata _odos
  ) public payable onlyRole(EXECUTOR_ROLE) {
    ensureNonzeroAddress(_stargateUSDCPool);
    ensureNonzeroAddress(_receiver);

    (bool ok,) = odos.call{value: msg.value}(_odos);
    require(ok, "odos call failed");

    uint256 balanceUSDC = IERC20(usdc).balanceOf(address(this));
    uint256 amount = calculatePercentage(balanceUSDC, 5000); // 50% of balance to send for buyback/burn on base chain.

    // Sending 50% revenue to sZAI stakers contract.
    sZAI.notifyRewardAmount(usdc, amount);
    _distributeRevenue(_stargateUSDCPool, _destinationEndPoint, balanceUSDC - amount, _receiver, _refundAddress);
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
    (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
      prepareTakeTaxi(_stargate, _dstEid, _amount, _receiver);
    IStargate(_stargate).sendToken{value: valueToSend}(sendParam, messagingFee, _refundAddress);
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
   * @return valueToSend The total native fee required to send the transaction, including the amount if Stargate is on a
   * native chain.
   * @return sendParam The `SendParam` structure containing all details needed for the cross-chain transaction.
   * @return messagingFee The `MessagingFee` structure containing the estimated native fees for the transaction.
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
  function calculatePercentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    require((amount * bps) >= 10_000, "amount * bps > 10_000");
    return (amount * bps) / 10_000;
  }

  /**
   * @notice Refunds the specified token balance held by the contract to the caller.
   * @dev Only callable by owner of the contract
   * @param token The ERC20 token to be refunded.
   */
  function refund(IERC20 token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }
}
