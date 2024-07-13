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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IZaiCore} from "../interfaces/IZaiCore.sol";
import {ZAIEventsLib} from "../interfaces/events/ZAIEventsLib.sol";

/**
 * @title Zai Core
 * @author maha.xyz
 * @notice Single source of truth for system-wide values and contract ownership.
 * Ownership of this contract should be the Zai DAO via `AdminVoting`.
 * Other ownable Zai contracts inherit their ownership from this contract
 * using `ZaiOwnable`.
 */
contract ZaiCore is Ownable, Pausable, IZaiCore {
    /// @inheritdoc IZaiCore
    address public feeReceiver;

    /// @inheritdoc IZaiCore
    address public priceFeed;

    /// @inheritdoc IZaiCore
    address public guardian;

    /// @inheritdoc IZaiCore
    uint256 public immutable startTime;

    constructor(
        address _owner,
        address _guardian,
        address _priceFeed,
        address _feeReceiver
    ) Ownable(_owner) {
        startTime = (block.timestamp / 1 weeks) * 1 weeks;
        guardian = _guardian;
        priceFeed = _priceFeed;
        feeReceiver = _feeReceiver;

        emit ZAIEventsLib.GuardianSet(_guardian);
        emit ZAIEventsLib.PriceFeedSet(_priceFeed);
        emit ZAIEventsLib.FeeReceiverSet(_feeReceiver);

        _transferOwnership(_owner);
    }

    /// @inheritdoc IZaiCore
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
        emit ZAIEventsLib.FeeReceiverSet(_feeReceiver);
    }

    /// @inheritdoc IZaiCore
    function setPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = _priceFeed;
        emit ZAIEventsLib.PriceFeedSet(_priceFeed);
    }

    /// @inheritdoc IZaiCore
    function setGuardian(address _guardian) external onlyOwner {
        guardian = _guardian;
        emit ZAIEventsLib.GuardianSet(_guardian);
    }

    /// @inheritdoc IZaiCore
    function owner()
        public
        view
        virtual
        override(IZaiCore, Ownable)
        returns (address)
    {
        return super.owner();
    }

    /// @inheritdoc IZaiCore
    function paused()
        public
        view
        virtual
        override(IZaiCore, Pausable)
        returns (bool)
    {
        return super.paused();
    }

    /// @inheritdoc IZaiCore
    function setPaused(bool what) external {
        require(
            (!paused() && msg.sender == guardian) || msg.sender == owner(),
            "Unauthorized"
        );
        if (what) _pause();
        else _unpause();
    }
}
