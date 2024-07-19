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

pragma solidity 0.8.20;

interface IAggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external pure returns (string memory);

  function getAnswer(uint256) external view returns (int256);

  function getTimestamp(uint256) external view returns (uint256);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function priceId() external view returns (bytes32);

  function pyth() external view returns (address);

  function updateFeeds(bytes[] calldata priceUpdateData) external payable;

  function version() external pure returns (uint256);
}
