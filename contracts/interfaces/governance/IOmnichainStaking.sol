// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

// ███████╗███████╗██████╗  ██████╗
// ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
//   ███╔╝ █████╗  ██████╔╝██║   ██║
//  ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
// ███████╗███████╗██║  ██║╚██████╔╝
// ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝

// Website: https://zerolend.xyz
// Discord: https://discord.gg/zerolend
// Twitter: https://twitter.com/zerolendxyz

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

import {IERC20, IMultiTokenRewards} from "../core/IMultiTokenRewards.sol";
import {ILocker} from "./ILocker.sol";

/**
 * @title OmnichainStaking interface
 * @author maha.xyz
 * @notice An omni-chain staking contract that allows users to stake their veNFT and get some
 * voting power. Once staked the voting power is available cross-chain.
 */
interface IOmnichainStaking is IMultiTokenRewards, IVotes {
  event LpOracleSet(address indexed oldLpOracle, address indexed newLpOracle);
  event ZeroAggregatorSet(address indexed oldZeroAggregator, address indexed newZeroAggregator);
  event Recovered(address token, uint256 amount);
  event RewardsDurationUpdated(uint256 newDuration);
  event TokenLockerUpdated(address previousLocker, address _tokenLocker);
  event RewardsTokenUpdated(address previousToken, address _zeroToken);
  event PoolVoterUpdated(address previousVoter, address _poolVoter);

  error InvalidUnstaker(address, address);

  /**
   * @notice The address of the rewards distributor.
   */
  function distributor() external view returns (address);

  /**
   * @notice The address of the WETH token.
   */
  function weth() external view returns (IERC20);

  /**
   * @notice The address of the locker contract.
   */
  function locker() external view returns (ILocker);

  /**
   * @notice How much voting power a given NFT ID has.
   * @param id The ID of the NFT.
   */
  function power(uint256 id) external view returns (uint256);

  /**
   * @notice used to keep track of ownership of token lockers
   * @param id The ID of the NFT.
   */
  function lockedByToken(uint256 id) external view returns (address);

  /**
   * @notice Gets the details of locked NFTs for a given user.
   * @param _user The address of the user.
   * @return lockedTokenIds The array of locked NFT IDs.
   * @return tokenDetails The array of locked NFT details.
   */
  function getLockedNftDetails(address _user) external view returns (uint256[] memory, ILocker.LockedBalance[] memory);

  /**
   * @notice Receives an ERC721 token from the lockers and grants voting power accordingly.
   * @param from The address sending the ERC721 token.
   * @param tokenId The ID of the ERC721 token.
   * @param data Additional data.
   * @return ERC721 onERC721Received selector.
   */
  function onERC721Received(address to, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);

  /**
   * @notice Unstakes a regular token NFT and transfers it back to the user.
   * @param tokenId The ID of the regular token NFT to unstake.
   */
  function unstakeToken(uint256 tokenId) external;

  /**
   * @notice Updates the lock duration for a specific NFT.
   * @param tokenId The ID of the NFT for which to update the lock duration.
   * @param newLockDuration The new lock duration in seconds.
   */
  function increaseLockDuration(uint256 tokenId, uint256 newLockDuration) external;

  /**
   * @notice Updates the lock amount for a specific NFT.
   * @param tokenId The ID of the NFT for which to update the lock amount.
   * @param newLockAmount The new lock amount in tokens.
   */
  function increaseLockAmount(uint256 tokenId, uint256 newLockAmount) external;

  /**
   * @notice Returns how much max voting power this locker will give out for the
   * given amount of tokens. This varies for the instance of locker.
   * @param amount The amount of tokens to give voting power for.
   */
  function getTokenPower(uint256 amount) external view returns (uint256 _power);

  /**
   * @notice The total number of NFTs staked in this contract for a user
   * @param who The address of the user.
   */
  function totalNFTStaked(address who) external view returns (uint256);

  /**
   * @dev Admin function to recover ERC20 tokens sent to this contract.
   * @param tokenAddress The address of the ERC20 token to recover.
   * @param tokenAmount The amount of tokens to recover.
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

  /**
   * Admin only function to set the rewards distributor
   *
   * @param what The new address for the rewards distributor
   */
  function setRewardDistributor(address what) external;

  /**
   * @dev This is an ETH variant of the get rewards function. It unwraps the token and sends out
   * raw ETH to the user.
   */
  function getRewardETH(address who) external;

  /**
   * @notice The total number of votes in this contract
   */
  function totalVotes() external view returns (uint256);
}
