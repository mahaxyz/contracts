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

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVestedZeroNFT} from "../interfaces/IVestedZeroNFT.sol";
import {IZeroLocker} from "../interfaces/IZeroLocker.sol";

/// @title StakingBonus Interface
/// @notice Interface for the StakingBonus contract that rewards users for converting unvested tokens into a 4-year stake
interface IStakingBonus {
    /**
     * @notice Initialize the contract with necessary parameters
     * @param _zero Address of the ZERO token contract
     * @param _locker Address of the locker contract
     * @param _vestedZERO Address of the VestedZERO NFT contract
     * @param _bonusBps Bonus basis points for calculating bonuses
     */
    function init(
        address _zero,
        address _locker,
        address _vestedZERO,
        uint256 _bonusBps
    ) external;

    /**
     * @notice Set the locker contract address
     * @param _locker Address of the new locker contract
     */
    function setLocker(address _locker) external;

    /**
     * @notice Set the VestedZERO contract address
     * @param _vestedZERO Address of the new VestedZERO contract
     */
    function setVestedZero(address _vestedZERO) external;

    /**
     * @notice Handle the receipt of an ERC721 token
     * @param from Address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return Selector to confirm function is implemented
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Create a lock with the specified amount and duration
     * @param amount The amount of tokens to lock
     * @param duration The lock duration in seconds
     * @param stake Whether the NFT should be staked
     */
    function createLock(uint256 amount, uint256 duration, bool stake) external;

    /**
     * @notice Create a lock for a specific address with the specified amount and duration
     * @param who The address for whom the lock is created
     * @param amount The amount of tokens to lock
     * @param duration The lock duration in seconds
     */
    function createLockFor(
        address who,
        uint256 amount,
        uint256 duration
    ) external;

    /**
     * @notice Set the bonus basis points
     * @param _bps The new bonus basis points
     */
    function setBonusBps(uint256 _bps) external;

    /**
     * @notice Calculate the bonus based on the amount and duration
     * @param amount The amount of tokens
     * @param duration The lock duration in seconds
     * @return The calculated bonus
     */
    function calculateBonus(
        uint256 amount,
        uint256 duration
    ) external view returns (uint256);

    /// @notice Emitted when the bonus basis points are set
    event SetBonusBPS(uint256 oldBps, uint256 newBps);
}
