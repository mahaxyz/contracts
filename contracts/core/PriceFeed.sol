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

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IAggregatorV3Interface} from "../interfaces/IAggregatorV3Interface.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {ZaiMath} from "./dependencies/ZaiMath.sol";
import {ZaiOwnable, IZaiCore, IZaiOwnable} from "./dependencies/ZaiOwnable.sol";

/**
 * @title Zai Multi Token Price Feed
 * @author maha.xyz
 * @notice Based on Gravita's PriceFeed:
 * https://github.com/Gravita-Protocol/Gravita-SmartContracts/blob/9b69d555f3567622b0f84df8c7f1bb5cd9323573/contracts/PriceFeed.sol
 * Zai's implementation additionally caches price values within a block
 * and incorporates exchange rate settings for derivative tokens (e.g. stETH -> wstETH).
 */
contract PriceFeed is ZaiOwnable, IPriceFeed {
    /** Constants ---------------------------------------------------------------------------------------------------- */

    // Used to convert a chainlink price answer to an 18-digit precision uint
    uint256 public constant TARGET_DIGITS = 18;

    // Responses are considered stale this many seconds after the oracle's heartbeat
    uint256 public constant RESPONSE_TIMEOUT_BUFFER = 1 hours;

    // Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
    uint256 public constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%

    // State ------------------------------------------------------------------------------------------------------------

    mapping(address => OracleRecord) internal _oracleRecords;

    mapping(address => PriceRecord) internal _priceRecords;

    struct OracleSetup {
        address token;
        address chainlink;
        uint32 heartbeat;
        bytes4 sharePriceSignature;
        uint8 sharePriceDecimals;
        bool isEthIndexed;
    }

    constructor(
        address _zaiCore,
        address ethFeed,
        OracleSetup[] memory oracles
    ) ZaiOwnable(_zaiCore) {
        _setOracle(address(0), ethFeed, 3600, 0, 0, false);
        for (uint i = 0; i < oracles.length; i++) {
            OracleSetup memory o = oracles[i];
            _setOracle(
                o.token,
                o.chainlink,
                o.heartbeat,
                o.sharePriceSignature,
                o.sharePriceDecimals,
                o.isEthIndexed
            );
        }
    }

    // Admin routines ---------------------------------------------------------------------------------------------------
    /// @inheritdoc IPriceFeed
    function setOracle(
        address _token,
        address _chainlinkOracle,
        uint32 _heartbeat,
        bytes4 sharePriceSignature,
        uint8 sharePriceDecimals,
        bool _isEthIndexed
    ) external onlyOwner {
        _setOracle(
            _token,
            _chainlinkOracle,
            _heartbeat,
            sharePriceSignature,
            sharePriceDecimals,
            _isEthIndexed
        );
    }

    function _setOracle(
        address _token,
        address _chainlinkOracle,
        uint32 _heartbeat,
        bytes4 sharePriceSignature,
        uint8 sharePriceDecimals,
        bool _isEthIndexed
    ) internal {
        if (_heartbeat > 86400) revert PriceFeed__HeartbeatOutOfBoundsError();
        IAggregatorV3Interface newFeed = IAggregatorV3Interface(
            _chainlinkOracle
        );
        (
            FeedResponse memory currResponse,
            FeedResponse memory prevResponse,

        ) = _fetchFeedResponses(newFeed, 0);

        if (!_isFeedWorking(currResponse, prevResponse)) {
            revert PriceFeed__InvalidFeedResponseError(_token);
        }
        if (_isPriceStale(currResponse.timestamp, _heartbeat)) {
            revert PriceFeed__FeedFrozenError(_token);
        }

        OracleRecord memory record = OracleRecord({
            chainLinkOracle: newFeed,
            decimals: newFeed.decimals(),
            heartbeat: _heartbeat,
            sharePriceSignature: sharePriceSignature,
            sharePriceDecimals: sharePriceDecimals,
            isFeedWorking: true,
            isEthIndexed: _isEthIndexed
        });

        _oracleRecords[_token] = record;
        PriceRecord memory _priceRecord = _priceRecords[_token];

        _processFeedResponses(
            _token,
            record,
            currResponse,
            prevResponse,
            _priceRecord
        );
        emit NewOracleRegistered(_token, _chainlinkOracle, _isEthIndexed);
    }

    // Public functions -------------------------------------------------------------------------------------------------

    /**
        @notice Get the latest price returned from the oracle
        @dev You can obtain these values by calling `TroveManager.fetchPrice()`
             rather than directly interacting with this contract.
        @param _token Token to fetch the price for
        @return The latest valid price for the requested token
     */
    function fetchPrice(address _token) public returns (uint256) {
        PriceRecord memory priceRecord = _priceRecords[_token];
        OracleRecord memory oracle = _oracleRecords[_token];

        uint256 scaledPrice = priceRecord.scaledPrice;
        // We short-circuit only if the price was already correct in the current block
        if (priceRecord.lastUpdated != block.timestamp) {
            if (priceRecord.lastUpdated == 0) {
                revert PriceFeed__UnknownFeedError(_token);
            }

            (
                FeedResponse memory currResponse,
                FeedResponse memory prevResponse,
                bool updated
            ) = _fetchFeedResponses(
                    oracle.chainLinkOracle,
                    priceRecord.roundId
                );

            if (updated) {
                scaledPrice = _processFeedResponses(
                    _token,
                    oracle,
                    currResponse,
                    prevResponse,
                    priceRecord
                );
            } else {
                if (_isPriceStale(priceRecord.timestamp, oracle.heartbeat)) {
                    revert PriceFeed__FeedFrozenError(_token);
                }

                priceRecord.lastUpdated = uint32(block.timestamp);
                _priceRecords[_token] = priceRecord;
            }
        }

        if (oracle.isEthIndexed) {
            uint256 ethPrice = fetchPrice(address(0));
            return (ethPrice * scaledPrice) / 1 ether;
        }
        return scaledPrice;
    }

    // Internal functions -----------------------------------------------------------------------------------------------

    function _processFeedResponses(
        address _token,
        OracleRecord memory oracle,
        FeedResponse memory _currResponse,
        FeedResponse memory _prevResponse,
        PriceRecord memory priceRecord
    ) internal returns (uint256) {
        uint8 decimals = oracle.decimals;
        bool isValidResponse = _isFeedWorking(_currResponse, _prevResponse) &&
            !_isPriceStale(_currResponse.timestamp, oracle.heartbeat) &&
            !_isPriceChangeAboveMaxDeviation(
                _currResponse,
                _prevResponse,
                decimals
            );
        if (isValidResponse) {
            uint256 scaledPrice = _scalePriceByDigits(
                uint256(_currResponse.answer),
                decimals
            );
            if (oracle.sharePriceSignature != 0) {
                (bool success, bytes memory returnData) = _token.staticcall(
                    abi.encode(oracle.sharePriceSignature)
                );
                require(success, "Share price not available");
                scaledPrice =
                    (scaledPrice * abi.decode(returnData, (uint256))) /
                    (10 ** oracle.sharePriceDecimals);
            }
            if (!oracle.isFeedWorking) {
                _updateFeedStatus(_token, oracle, true);
            }
            _storePrice(
                _token,
                scaledPrice,
                _currResponse.timestamp,
                _currResponse.roundId
            );
            return scaledPrice;
        } else {
            if (oracle.isFeedWorking) {
                _updateFeedStatus(_token, oracle, false);
            }
            if (_isPriceStale(priceRecord.timestamp, oracle.heartbeat)) {
                revert PriceFeed__FeedFrozenError(_token);
            }
            return priceRecord.scaledPrice;
        }
    }

    function _fetchFeedResponses(
        IAggregatorV3Interface oracle,
        uint80 lastRoundId
    )
        internal
        view
        returns (
            FeedResponse memory currResponse,
            FeedResponse memory prevResponse,
            bool updated
        )
    {
        currResponse = _fetchCurrentFeedResponse(oracle);
        if (lastRoundId == 0 || currResponse.roundId > lastRoundId) {
            prevResponse = _fetchPrevFeedResponse(oracle, currResponse.roundId);
            updated = true;
        }
    }

    function _isPriceStale(
        uint256 _priceTimestamp,
        uint256 _heartbeat
    ) internal view returns (bool) {
        return
            block.timestamp - _priceTimestamp >
            _heartbeat + RESPONSE_TIMEOUT_BUFFER;
    }

    function _isFeedWorking(
        FeedResponse memory _currentResponse,
        FeedResponse memory _prevResponse
    ) internal view returns (bool) {
        return
            _isValidResponse(_currentResponse) &&
            _isValidResponse(_prevResponse);
    }

    function _isValidResponse(
        FeedResponse memory _response
    ) internal view returns (bool) {
        return
            (_response.success) &&
            (_response.roundId != 0) &&
            (_response.timestamp != 0) &&
            (_response.timestamp <= block.timestamp) &&
            (_response.answer != 0);
    }

    function _isPriceChangeAboveMaxDeviation(
        FeedResponse memory _currResponse,
        FeedResponse memory _prevResponse,
        uint8 decimals
    ) internal pure returns (bool) {
        uint256 currentScaledPrice = _scalePriceByDigits(
            uint256(_currResponse.answer),
            decimals
        );
        uint256 prevScaledPrice = _scalePriceByDigits(
            uint256(_prevResponse.answer),
            decimals
        );

        uint256 minPrice = ZaiMath._min(currentScaledPrice, prevScaledPrice);
        uint256 maxPrice = ZaiMath._max(currentScaledPrice, prevScaledPrice);

        /*
         * Use the larger price as the denominator:
         * - If price decreased, the percentage deviation is in relation to the previous price.
         * - If price increased, the percentage deviation is in relation to the current price.
         */
        uint256 percentDeviation = ((maxPrice - minPrice) *
            ZaiMath.DECIMAL_PRECISION) / maxPrice;

        return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
    }

    function _scalePriceByDigits(
        uint256 _price,
        uint256 _answerDigits
    ) internal pure returns (uint256) {
        if (_answerDigits == TARGET_DIGITS) {
            return _price;
        } else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to target precision
            return _price * (10 ** (TARGET_DIGITS - _answerDigits));
        } else {
            // Scale the returned price value down to target precision
            return _price / (10 ** (_answerDigits - TARGET_DIGITS));
        }
    }

    function _updateFeedStatus(
        address _token,
        OracleRecord memory _oracle,
        bool _isWorking
    ) internal {
        _oracleRecords[_token].isFeedWorking = _isWorking;
        emit PriceFeedStatusUpdated(
            _token,
            address(_oracle.chainLinkOracle),
            _isWorking
        );
    }

    function _storePrice(
        address _token,
        uint256 _price,
        uint256 _timestamp,
        uint80 roundId
    ) internal {
        _priceRecords[_token] = PriceRecord({
            scaledPrice: uint96(_price),
            timestamp: uint32(_timestamp),
            lastUpdated: uint32(block.timestamp),
            roundId: roundId
        });
        emit PriceRecordUpdated(_token, _price);
    }

    function _fetchCurrentFeedResponse(
        IAggregatorV3Interface _priceAggregator
    ) internal view returns (FeedResponse memory response) {
        try _priceAggregator.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        ) {
            // If call to Chainlink succeeds, return the response and success = true
            response.roundId = roundId;
            response.answer = answer;
            response.timestamp = timestamp;
            response.success = true;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return response;
        }
    }

    function _fetchPrevFeedResponse(
        IAggregatorV3Interface _priceAggregator,
        uint80 _currentRoundId
    ) internal view returns (FeedResponse memory prevResponse) {
        if (_currentRoundId == 0) {
            return prevResponse;
        }
        unchecked {
            try _priceAggregator.getRoundData(_currentRoundId - 1) returns (
                uint80 roundId,
                int256 answer,
                uint256 /* startedAt */,
                uint256 timestamp,
                uint80 /* answeredInRound */
            ) {
                prevResponse.roundId = roundId;
                prevResponse.answer = answer;
                prevResponse.timestamp = timestamp;
                prevResponse.success = true;
            } catch {}
        }
    }

    /// @inheritdoc IPriceFeed
    function oracleRecords(
        address what
    ) external view override returns (OracleRecord memory) {
        return _oracleRecords[what];
    }

    /// @inheritdoc IPriceFeed
    function priceRecords(
        address what
    ) external view override returns (PriceRecord memory) {
        return _priceRecords[what];
    }
}
