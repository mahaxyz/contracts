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

library ConnextErrors {
  /// @dev Error for 0x0 address inputs
  error InvalidZeroInput();

  /// @dev error when function returns 0 amount
  error InvalidZeroOutput();

  /// @dev Error when the sender is not expected
  error InvalidSender(address expectedSender, address actualSender);

  /// @dev Error when the token received over the bridge is not the one expected
  error InvalidTokenReceived();

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
}
