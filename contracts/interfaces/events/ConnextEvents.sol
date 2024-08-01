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

library ConnextEvents {
  /// @dev Event emitted when bridge triggers mint
  event ZaiMinted(bytes32 transferId, uint256 amountDeposited, uint32 origin, address originSender, uint256 minted);

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

  event Deposit(address indexed user, uint256 amountIn, uint256 amountOut);
  event BridgeSweeperAddressUpdated(address sweeper, bool allowed);
  event BridgeSwept(uint32 destinationDomain, address destinationTarget, address delegate, uint256 amount);
  event RateUpdated(uint256 newRate, uint256 oldRate);
  event ReceiverPriceFeedUpdated(address newReceiver, address oldReceiver);
  event SweeperBridgeFeeCollected(address sweeper, uint256 feeCollected);
  event BridgeFeeShareUpdated(uint256 oldBridgeFeeShare, uint256 newBridgeFeeShare);
  event SweepBatchSizeUpdated(uint256 oldSweepBatchSize, uint256 newSweepBatchSize);
}
