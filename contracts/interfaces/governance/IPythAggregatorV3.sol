// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPythAggregatorV3 {
    function decimals() external view returns (uint8);
    function description() external pure returns (string memory);
    function getAnswer(uint256) external view returns (int256);
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function getTimestamp(uint256) external view returns (uint256);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint256);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestTimestamp() external view returns (uint256);
    function priceId() external view returns (bytes32);
    function pyth() external view returns (address);

    function updateFeeds(bytes[] calldata priceUpdateData) external payable;
    function version() external pure returns (uint256);
}
