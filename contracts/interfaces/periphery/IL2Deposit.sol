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

interface IL2Deposit {
  event PriceUpdated(uint256 price, uint256 timestamp);
  event Deposit(address indexed user, uint256 amountIn, uint256 amountOut);
  event BridgeSweeperAddressUpdated(address sweeper, bool allowed);
  event BridgeSwept(
    uint32 destinationDomain,
    address destinationTarget,
    address delegate,
    uint256 amount
  );
  event RateUpdated(uint256 newRate, uint256 oldRate);
  event ReceiverPriceFeedUpdated(address newReceiver, address oldReceiver);
  event SweeperBridgeFeeCollected(address sweeper, uint256 feeCollected);
  event BridgeFeeShareUpdated(
    uint256 oldBridgeFeeShare,
    uint256 newBridgeFeeShare
  );
  event SweepBatchSizeUpdated(
    uint256 oldSweepBatchSize,
    uint256 newSweepBatchSize
  );

  /// @dev Error for invalid bridge fee share configuration
  error InvalidBridgeFeeShare(uint256 bridgeFee);

  /// @dev Error for invalid sweep batch size
  error InvalidSweepBatchSize(uint256 batchSize);

  /// @dev Error when sending ETH fails
  error TransferFailed();

  /// @dev Error when an unauthorized address tries to call the bridge function on the L2
  error UnauthorizedBridgeSweeper();

  /// @dev Error when trade does not meet minimum output amount
  error InsufficientOutputAmount();

  /// @dev Error for 0x0 address inputs
  error InvalidZeroInput();

  /// @dev error when function returns 0 amount
  error InvalidZeroOutput();

  /// @dev Error when the sender is not expected
  error InvalidSender(address expectedSender, address actualSender);

  /// @dev Error when the token received over the bridge is not the one expected
  error InvalidTokenReceived();

  function deposit(
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _deadline
  ) external returns (uint256);

  function sweep() external payable;

  function updatePrice(uint256 price, uint256 timestamp) external;
}
