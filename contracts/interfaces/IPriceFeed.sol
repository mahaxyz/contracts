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

import {IAggregatorV3Interface} from "./IAggregatorV3Interface.sol";

interface IPriceFeed {
    struct OracleRecord {
        IAggregatorV3Interface chainLinkOracle;
        uint8 decimals;
        uint32 heartbeat;
        bytes4 sharePriceSignature;
        uint8 sharePriceDecimals;
        bool isFeedWorking;
        bool isEthIndexed;
    }

    struct PriceRecord {
        uint96 scaledPrice;
        uint32 timestamp;
        uint32 lastUpdated;
        uint80 roundId;
    }

    struct FeedResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
    }

    // Custom Errors --------------------------------------------------------------------------------------------------

    error PriceFeed__InvalidFeedResponseError(address token);
    error PriceFeed__FeedFrozenError(address token);
    error PriceFeed__UnknownFeedError(address token);
    error PriceFeed__HeartbeatOutOfBoundsError();

    event NewOracleRegistered(
        address token,
        address chainlinkAggregator,
        bool isEthIndexed
    );
    event PriceFeedStatusUpdated(address token, address oracle, bool isWorking);
    event PriceRecordUpdated(address indexed token, uint256 _price);

    function fetchPrice(address _token) external returns (uint256);

    function setOracle(
        address _token,
        address _chainlinkOracle,
        bytes4 sharePriceSignature,
        uint8 sharePriceDecimals,
        bool _isEthIndexed
    ) external;

    function MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND()
        external
        view
        returns (uint256);

    // function RESPONSE_TIMEOUT() external view returns (uint256);

    function TARGET_DIGITS() external view returns (uint256);

    function oracleRecords(address) external view returns (OracleRecord memory);

    function priceRecords(address) external view returns (PriceRecord memory);
}
