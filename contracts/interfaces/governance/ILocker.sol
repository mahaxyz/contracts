// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title ILocker Interface
/// @notice Interface for a contract that handles locking ERC20 tokens in exchange for NFT representations
interface ILocker is IERC721Enumerable {
  /**
   * @notice Structure to store locked balance information
   * @param amount Amount of tokens locked
   * @param end End time of the lock period (timestamp)
   * @param start Start time of the lock period (timestamp)
   * @param power Additional parameter, potentially for governance or staking power
   */
  struct LockedBalance {
    uint256 amount;
    uint256 end;
    uint256 start;
    uint256 power;
  }

  /**
   * @notice Get the balance associated with an NFT
   * @param _tokenId The NFT ID
   * @return The balance of the NFT
   */
  function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

  /**
   * @notice Get the underlying ERC20 token
   * @return The ERC20 token contract
   */
  function underlying() external view returns (IERC20);

  /**
   * @notice Get the balance of an NFT at a specific time
   * @param _tokenId The NFT ID
   * @param _t The specific time (timestamp)
   * @return The balance of the NFT at time _t
   */
  function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256);

  /**
   * @notice Get the locked balance details of an NFT
   * @param _tokenId The NFT ID
   * @return The LockedBalance struct containing lock details
   */
  function locked(uint256 _tokenId) external view returns (LockedBalance memory);

  /**
   * @notice Get the end time of the lock for a specific NFT
   * @param _tokenId The NFT ID
   * @return The end time of the lock period (timestamp)
   */
  function lockedEnd(uint256 _tokenId) external view returns (uint256);

  /**
   * @notice Get the voting power of a specific address
   * @param _owner The address of the owner
   * @return _power The voting power of the owner
   */
  function votingPowerOf(address _owner) external view returns (uint256 _power);

  /**
   * @notice Merge two NFTs into one
   * @param _from The ID of the NFT to merge from
   * @param _to The ID of the NFT to merge into
   */
  function merge(uint256 _from, uint256 _to) external;

  /**
   * @notice Deposit tokens for a specific NFT
   * @param _tokenId The ID of the NFT
   * @param _value The amount of tokens to deposit
   */
  function depositFor(uint256 _tokenId, uint256 _value) external;

  /**
   * @notice Create a lock for a specified amount and duration
   * @param _value The amount of tokens to lock
   * @param _lockDuration The lock duration in seconds
   * @param _stakeNFT Whether the NFT should be staked
   * @return The ID of the created NFT
   */
  function createLock(uint256 _value, uint256 _lockDuration, bool _stakeNFT) external returns (uint256);

  /**
   * @notice Increase the amount of tokens locked in a specific NFT
   * @param _tokenId The ID of the NFT
   * @param _value The additional amount of tokens to lock
   */
  function increaseAmount(uint256 _tokenId, uint256 _value) external;

  /**
   * @notice Extend the unlock time for an NFT
   * @param _lockDuration New number of seconds until tokens unlock
   */
  function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external;

  /**
   * @notice Create a lock for a specified amount, duration, and recipient
   * @param _value The amount of tokens to lock
   * @param _lockDuration The lock duration in seconds
   * @param _to The address to receive the NFT
   * @param _stakeNFT Whether the NFT should be staked
   * @return The ID of the created NFT
   */
  function createLockFor(uint256 _value, uint256 _lockDuration, address _to, bool _stakeNFT) external returns (uint256);

  /**
   * @notice Withdraw tokens from a specific NFT
   * @param _tokenId The ID of the NFT
   */
  function withdraw(uint256 _tokenId) external;

  /**
   * @notice Withdraw tokens from multiple NFTs
   * @param _tokenIds An array of NFT IDs
   */
  function withdraw(uint256[] calldata _tokenIds) external;

  /**
   * @notice Withdraw tokens for a specific user
   * @param _user The address of the user
   */
  function withdraw(address _user) external;
}
