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

pragma solidity 0.8.21;

import {ILocker} from "./interfaces/governance/ILocker.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MigratorMaha
 * @notice This contract facilitates the migration of locked assets and distributes bonus MAHA tokens to eligible users.
 * @dev Implements migration functionality using a Merkle tree for verification and interacts with an ILocker contract.
 *      Includes features such as pausing, owner control, and token refunds.
 */
contract MigratorMaha is Ownable2StepUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20 for IERC20;

  /// @notice Merkle root used to verify the migration eligibility of users.
  bytes32 public merkleRoot;

  /// @notice Address of the MAHA token contract used for bonus distribution.
  IERC20 public maha;

  /// @notice Address of the ILocker contract for lock creation.
  ILocker public locker;

  /// @notice Tracks whether an NFT ID has already been migrated.
  mapping(uint256 => bool) public isTokenIdMigrated;

  // -------------------- Errors --------------------

  /// @notice Thrown when attempting to migrate an already migrated NFT ID.
  /// @param nftId The ID of the NFT that was already migrated.
  error AlreadyMigrated(uint256 nftId);

  /// @notice Thrown when the migration process fails.
  /// @param nftId The ID of the NFT for which migration failed.
  error MigrationFailed(uint256 nftId);

  /// @notice Thrown when an invalid or zero NFT ID is provided.
  /// @param nftId The invalid NFT ID.
  error InvalidTokenId(uint256 nftId);

  /// @notice Thrown when an invalid Merkle proof is submitted.
  /// @param proof The invalid Merkle proof.
  error InvalidMerkleProof(bytes32[] proof);

  /// @notice Thrown when a zero address is provided where an address is required.
  error InvalidZeroAddress();

  /// @notice Thrown when the lock's end time is already expired or invalid.
  /// @param endTime The invalid end time provided.
  error EndTimeExpired(uint256 endTime);

  // -------------------- Events --------------------

  /**
   * @notice Event emitted when a migration is successfully completed.
   * @param user The address of the user who migrated.
   * @param nftId The ID of the NFT issued to the user.
   * @param bonus The amount of bonus MAHA tokens distributed.
   */
  event Migrated(address indexed user, uint256 indexed nftId, uint256 bonus);

  /**
   * @notice Event emitted when the Merkle root is updated.
   * @param oldMerkleRoot The previous Merkle root.
   * @param newMerkleRoot The new Merkle root.
   */
  event MerkleRootUpdated(bytes32 oldMerkleRoot, bytes32 newMerkleRoot);

  // -------------------- Functions --------------------

  /**
   * @notice Initializes the contract with initial values.
   * @param _merkleRoot The Merkle root for verifying eligibility.
   * @param _maha The MAHA token contract address.
   * @param _locker The ILocker contract address.
   */
  function initialize(bytes32 _merkleRoot, IERC20 _maha, ILocker _locker) external initializer {
    __Ownable_init(msg.sender);
    __Pausable_init();
    merkleRoot = _merkleRoot;
    maha = _maha;
    locker = _locker;
  }

  /**
   * @notice Facilitates the migration of locked assets.
   * @param _user The address of the user initiating the migration.
   * @param _nftId The ID of the NFT to be migrated.
   * @param _mahaLocked The amount of MAHA tokens to be locked.
   * @param _startTime The start time of the lock.
   * @param _endTime The end time of the lock.
   * @param _mahaBonus The amount of bonus MAHA tokens to be distributed.
   * @param _stakeNFT Whether to stake the NFT or not.
   * @param proof The Merkle proof verifying the user's eligibility.
   * @dev Emits a `Migrated` event upon success.
   *      Reverts with appropriate errors for invalid data or migration conditions.
   */
  function migrateLock(
    address _user,
    uint256 _nftId,
    uint256 _mahaLocked,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _mahaBonus,
    bool _stakeNFT,
    bytes32[] calldata proof
  ) external nonReentrant whenNotPaused {
    _migrateLock(_user, _nftId, _mahaLocked, _startTime, _endTime, _mahaBonus, _stakeNFT, proof);
  }

  /**
   * @notice Verifies the validity of a migration lock using the Merkle tree.
   * @param _user The user's address.
   * @param _nftId The NFT ID.
   * @param _mahaLocked The amount of locked MAHA tokens.
   * @param _startTime The lock's start time.
   * @param _endTime The lock's end time.
   * @param _mahaBonus The bonus MAHA tokens.
   * @param _proof The Merkle proof.
   * @return bool Returns `true` if the lock is valid, otherwise reverts.
   */
  function isValidLock(
    address _user,
    uint256 _nftId,
    uint256 _mahaLocked,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _mahaBonus,
    bytes32[] calldata _proof
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_user, _nftId, _mahaLocked, _startTime, _endTime, _mahaBonus));
    if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
      revert InvalidMerkleProof(_proof);
    }
    return true;
  }

  /**
   * @notice Updates the Merkle root used for migration verification.
   * @param _newMerkleRoot The new Merkle root.
   * @dev Only callable by the owner. Emits a `MerkleRootUpdated` event.
   */
  function updateMerkleRoot(
    bytes32 _newMerkleRoot
  ) external onlyOwner {
    bytes32 oldMerkleRoot = merkleRoot;
    merkleRoot = _newMerkleRoot;
    emit MerkleRootUpdated(oldMerkleRoot, _newMerkleRoot);
  }

  /**
   * @notice Toggles the paused state of the contract.
   * @dev Only callable by the owner. Pauses or unpauses the contract.
   */
  function togglePause() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  /**
   * @notice Refunds the contract's token balance to the owner.
   * @param token The ERC20 token to refund.
   * @dev Transfers the entire token balance of the contract to the owner.
   */
  function refund(
    IERC20 token
  ) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  /**
   * @dev Internal function to handle migration logic.
   * @param _user The address of the user initiating the migration.
   * @param _nftId The ID of the NFT to be migrated.
   * @param _mahaLocked The amount of MAHA tokens to be locked.
   * @param _startTime The start time of the lock.
   * @param _endTime The end time of the lock.
   * @param _mahaBonus The amount of bonus MAHA tokens to be distributed.
   * @param _stakeNFT Whether to stake the NFT or not.
   * @param proof The Merkle proof verifying the user's eligibility.
   */
  function _migrateLock(
    address _user,
    uint256 _nftId,
    uint256 _mahaLocked,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _mahaBonus,
    bool _stakeNFT,
    bytes32[] calldata proof
  ) internal {
    if (_user == address(0)) {
      revert InvalidZeroAddress();
    }
    if (isTokenIdMigrated[_nftId]) {
      revert AlreadyMigrated(_nftId);
    }
    if (_nftId == 0) {
      revert InvalidTokenId(_nftId);
    }
    if (_endTime < (block.timestamp + 2 weeks)) {
      revert EndTimeExpired(_endTime);
    }

    isValidLock(_user, _nftId, _mahaLocked, _startTime, _endTime, _mahaBonus, proof);
    uint256 _lockDuration = _endTime - block.timestamp;

    uint256 tokenId = locker.createLockFor(_mahaLocked, _lockDuration, _user, _stakeNFT);

    if (tokenId == 0) {
      revert MigrationFailed(tokenId);
    }

    isTokenIdMigrated[_nftId] = true;

    if (_mahaBonus > 0) maha.safeTransfer(msg.sender, _mahaBonus);

    emit Migrated(_user, _nftId, _mahaBonus);
  }
}
