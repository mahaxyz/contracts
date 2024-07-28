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

// An omni-chain staking contract that allows users to stake their veNFT
// and get some voting power. Once staked the voting power is available cross-chain.
interface IOmnichainStaking is IMultiTokenRewards, IVotes {
  event LpOracleSet(address indexed oldLpOracle, address indexed newLpOracle);
  event ZeroAggregatorSet(address indexed oldZeroAggregator, address indexed newZeroAggregator);
  event Recovered(address token, uint256 amount);
  event RewardsDurationUpdated(uint256 newDuration);
  event TokenLockerUpdated(address previousLocker, address _tokenLocker);
  event RewardsTokenUpdated(address previousToken, address _zeroToken);
  event PoolVoterUpdated(address previousVoter, address _poolVoter);

  error InvalidUnstaker(address, address);

  /// @notice Account that distributes staking rewards
  function distributor() external view returns (address);
  function weth() external view returns (IERC20);
  function locker() external view returns (ILocker);
  /// @notice used to keep track of voting powers for each nft id
  function power(uint256 id) external view returns (uint256);

  /// @notice used to keep track of ownership of token lockers
  function lockedByToken(uint256 id) external view returns (address);

  /**
   * @dev Gets the details of locked NFTs for a given user.
   * @param _user The address of the user.
   * @return lockedTokenIds The array of locked NFT IDs.
   * @return tokenDetails The array of locked NFT details.
   */
  function getLockedNftDetails(address _user) external view returns (uint256[] memory, ILocker.LockedBalance[] memory);

  /**
   * @dev Receives an ERC721 token from the lockers and grants voting power accordingly.
   * @param from The address sending the ERC721 token.
   * @param tokenId The ID of the ERC721 token.
   * @param data Additional data.
   * @return ERC721 onERC721Received selector.
   */
  function onERC721Received(address to, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);

  /**
   * @dev Unstakes a regular token NFT and transfers it back to the user.
   * @param tokenId The ID of the regular token NFT to unstake.
   */
  function unstakeToken(uint256 tokenId) external;

  /**
   * @dev Updates the lock duration for a specific NFT.
   * @param tokenId The ID of the NFT for which to update the lock duration.
   * @param newLockDuration The new lock duration in seconds.
   */
  function increaseLockDuration(uint256 tokenId, uint256 newLockDuration) external;

  /**
   * @dev Updates the lock amount for a specific NFT.
   * @param tokenId The ID of the NFT for which to update the lock amount.
   * @param newLockAmount The new lock amount in tokens.
   */
  function increaseLockAmount(uint256 tokenId, uint256 newLockAmount) external;

  /**
   * Returns how much max voting power this locker will give out for the
   * given amount of tokens. This varies for the instance of locker.
   *
   * @param amount The amount of tokens to give voting power for.
   */
  function getTokenPower(uint256 amount) external view returns (uint256 _power);

  function totalNFTStaked(address who) external view returns (uint256);

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

  function totalVotes() external view returns (uint256);
}
