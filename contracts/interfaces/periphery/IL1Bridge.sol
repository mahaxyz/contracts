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

interface IL1Bridge {
  /// @dev Event emitted when bridge triggers mint
  event ZaiMinted(bytes32 transferId, uint256 amountDeposited, uint32 origin, address originSender, uint256 minted);

  /// @dev Error for 0x0 address inputs
  error InvalidZeroInput();

  /// @dev error when function returns 0 amount
  error InvalidZeroOutput();

  /// @dev Error when the sender is not expected
  error InvalidSender(address expectedSender, address actualSender);

  /// @dev Error when the token received over the bridge is not the one expected
  error InvalidTokenReceived();

  /// @dev Event emitted when a message is sent to another chain.
  // The chain selector of the destination chain.
  // The address of the receiver on the destination chain.
  // The exchange rate sent.
  // the token address used to pay CCIP fees.
  // The fees paid for sending the CCIP message.
  // The unique ID of the CCIP message.
  event MessageSent(
    bytes32 indexed messageId,
    uint64 indexed destinationChainSelector,
    address receiver,
    uint256 exchangeRate,
    address feeToken,
    uint256 fees
  );

  event ConnextMessageSent(uint32 indexed destinationChainDomain, address receiver, uint256 exchangeRate, uint256 fees);

  /**
   * @notice  Accepts collateral from the bridge
   * @dev     This function will take all collateral and deposit it into Renzo
   *          The ezETH from the deposit will be sent to the lockbox to be wrapped into xezETH
   *          The xezETH will be burned so that the xezETH on the L2 can be unwrapped for ezETH later
   * @notice  WARNING: This function does NOT whitelist who can send funds from the L2 via Connext.  Users should NOT
   *          send funds directly to this contract.  A user who sends funds directly to this contract will cause
   *          the tokens on the L2 to become over collateralized and will be a "donation" to protocol.  Only use
   *          the deposit contracts on the L2 to send funds to this contract.
   */
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory
  ) external returns (bytes memory);
}
