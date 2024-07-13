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

/**
 * @title Zai Core
 * @author maha.xyz
 * @notice Single source of truth for system-wide values and contract ownership.
 * Ownership of this contract should be the Zai DAO via `AdminVoting`.
 * Other ownable Zai contracts inherit their ownership from this contract
 * using `ZaiOwnable`.
 */
contract ZaiCore is Ownable, Pausable {
    address public feeReceiver;
    address public priceFeed;
    address public owner;
    address public pendingOwner;
    uint256 public ownershipTransferDeadline;
    address public guardian;

    // System-wide start time, rounded down the nearest epoch week.
    // Other contracts that require access to this should inherit `SystemStart`.
    uint256 public immutable startTime;

    constructor(
        address _owner,
        address _guardian,
        address _priceFeed,
        address _feeReceiver
    ) {
        owner = _owner;
        startTime = (block.timestamp / 1 weeks) * 1 weeks;
        guardian = _guardian;
        priceFeed = _priceFeed;
        feeReceiver = _feeReceiver;

        emit GuardianSet(_guardian);
        emit PriceFeedSet(_priceFeed);
        emit FeeReceiverSet(_feeReceiver);

        _transferOwnership(_owner);
    }

    /**
     * @notice Set the receiver of all fees across the protocol
     * @param _feeReceiver Address of the fee's recipient
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
        emit FeeReceiverSet(_feeReceiver);
    }

    /**
     * @notice Set the price feed used in the protocol
     * @param _priceFeed Price feed address
     */
    function setPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = _priceFeed;
        emit PriceFeedSet(_priceFeed);
    }

    /**
     * @notice Set the guardian address. The guardian can execute some emergency actions
     * @param _guardian Guardian address
     */
    function setGuardian(address _guardian) external onlyOwner {
        guardian = _guardian;
        emit GuardianSet(_guardian);
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
