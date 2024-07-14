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

import {ILocker} from "../../interfaces/governance/ILocker.sol";
import {IOmnichainStaking} from "../../interfaces/governance/IOmnichainStaking.sol";
import {
  ERC721EnumerableUpgradeable,
  IERC165
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title Voting Escrow
 * @author maha.xyz
 * @notice Votes have a weight depending on time, so that users are
 * committed to the future of (whatever they are voting for)
 */
abstract contract BaseLocker is ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable, ILocker {
// uint256 internal WEEK;
// uint256 internal MAXTIME;
// uint256 internal MULTIPLIER;
// uint256 public supply;
// mapping(uint256 => LockedBalance) public locked;
// string public version;
// uint8 public decimals;
// /// @dev Current count of token
// uint256 internal tokenId;
// IERC20 public underlying;
// IOmnichainStaking public staking;
// function __BaseLocker_init(
//     string memory _name,
//     string memory _symbol,
//     address _token,
//     address _staking,
//     uint256 _maxTime
// ) internal {
//     __ERC721_init(_name, _symbol);
//     __ReentrancyGuard_init();
//     version = "1.0.0";
//     decimals = 18;
//     WEEK = 1 weeks;
//     MAXTIME = _maxTime;
//     MULTIPLIER = 1 ether;
//     staking = IOmnichainStaking(_staking);
//     underlying = IERC20(_token);
//     _setApprovalForAll(address(this), _staking, true);
// }
// /// @dev Interface identification is specified in ERC-165.
// /// @param _interfaceID Id of the interface
// function supportsInterface(
//     bytes4 _interfaceID
// )
//     public
//     view
//     override(ERC721EnumerableUpgradeable, IERC165)
//     returns (bool)
// {
//     return ERC721EnumerableUpgradeable.supportsInterface(_interfaceID);
// }
// /// @notice Get timestamp when `_tokenId`'s lock finishes
// /// @param _tokenId User NFT
// /// @return Epoch time of the lock end
// function lockedEnd(uint256 _tokenId) external view returns (uint256) {
//     return locked[_tokenId].end;
// }
// /// @dev Returns the voting power of the `_owner`.
// ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
// /// @param _owner Address for whom to query the voting power of.
// function votingPowerOf(
//     address _owner
// ) external view returns (uint256 _power) {
//     for (uint256 index = 0; index < balanceOf(_owner); index++) {
//         uint256 _tokenId = tokenOfOwnerByIndex(_owner, index);
//         _power += balanceOfNFT(_tokenId);
//     }
// }
// function _calculatePower(
//     LockedBalance memory lock
// ) internal view returns (uint256 power) {
//     power = ((lock.end - lock.start) * lock.amount) / MAXTIME;
// }
// /// @notice Deposit and lock tokens for a user
// /// @param _tokenId NFT that holds lock
// /// @param _value Amount to deposit
// /// @param _unlockTime New time when to unlock the tokens, or 0 if unchanged
// /// @param _lock Previous locked amount / timestamp
// /// @param _type The type of deposit
// function _depositFor(
//     uint256 _tokenId,
//     uint256 _value,
//     uint256 _unlockTime,
//     LockedBalance memory _lock,
//     DepositType _type
// ) internal virtual {
//     LockedBalance memory lock = _lock;
//     uint256 supplyBefore = supply;
//     supply = supplyBefore + _value;
//     LockedBalance memory oldLocked;
//     (oldLocked.amount, oldLocked.end, oldLocked.power) = (
//         lock.amount,
//         lock.end,
//         lock.power
//     );
//     // Adding to existing lock, or if a lock is expired - creating a new one
//     lock.amount += _value;
//     if (_unlockTime != 0) lock.end = _unlockTime;
//     if (_type == DepositType.CREATE_LOCK_TYPE) lock.start = block.timestamp;
//     lock.power = _calculatePower(lock);
//     locked[_tokenId] = lock;
//     // Possibilities:
//     // Both oldLocked.end could be current or expired (>/< block.timestamp)
//     // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
//     // _locked.end > block.timestamp (always)
//     if (_value != 0 && _type != DepositType.MERGE_TYPE)
//         assert(underlying.transferFrom(msg.sender, address(this), _value));
//     emit Deposit(
//         msg.sender,
//         _tokenId,
//         _value,
//         lock.end,
//         _type,
//         block.timestamp
//     );
//     emit Supply(supplyBefore, supplyBefore + _value);
// }
// function merge(uint256 _from, uint256 _to) external override {
//     require(_from != _to, "same nft");
//     require(
//         _isAuthorized(ownerOf(_from), msg.sender, _from),
//         "from not approved"
//     );
//     require(
//         _isAuthorized(ownerOf(_to), msg.sender, _to),
//         "to not approved"
//     );
//     LockedBalance memory _locked0 = locked[_from];
//     LockedBalance memory _locked1 = locked[_to];
//     uint256 value0 = uint256(int256(_locked0.amount));
//     uint256 end = _locked0.end >= _locked1.end
//         ? _locked0.end
//         : _locked1.end;
//     locked[_from] = LockedBalance(0, 0, 0, 0);
//     _burn(_from);
//     _depositFor(_to, value0, end, _locked1, DepositType.MERGE_TYPE);
// }
// /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
// /// @dev Anyone (even a smart contract) can deposit for someone else, but
// ///      cannot extend their locktime and deposit for a brand new user
// /// @param _tokenId lock NFT
// /// @param _value Amount to add to user's lock
// function depositFor(
//     uint256 _tokenId,
//     uint256 _value
// ) external override nonReentrant {
//     LockedBalance memory _locked = locked[_tokenId];
//     require(_value > 0, "value = 0"); // dev: need non-zero value
//     require(_locked.amount > 0, "No existing lock found");
//     require(_locked.end > block.timestamp, "Cannot add to expired lock.");
//     _depositFor(_tokenId, _value, 0, _locked, DepositType.DEPOSIT_FOR_TYPE);
// }
// /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
// /// @param _value Amount to deposit
// /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
// /// @param _to Address to deposit
// function createLockFor(
//     uint256 _value,
//     uint256 _lockDuration,
//     address _to,
//     bool _stakeNFT
// ) external override nonReentrant returns (uint256) {
//     return _createLock(_value, _lockDuration, _to, _stakeNFT);
// }
// /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
// /// @param _value Amount to deposit
// /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
// /// @param _stakeNFT Should we also stake the NFT as well?
// function createLock(
//     uint256 _value,
//     uint256 _lockDuration,
//     bool _stakeNFT
// ) external override nonReentrant returns (uint256) {
//     return _createLock(_value, _lockDuration, msg.sender, _stakeNFT);
// }
// /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
// /// @param _value Amount of tokens to deposit and add to the lock
// function increaseAmount(
//     uint256 _tokenId,
//     uint256 _value
// ) external nonReentrant {
//     require(
//         _isAuthorized(_ownerOf(_tokenId), msg.sender, _tokenId),
//         "caller is not owner nor approved"
//     );
//     LockedBalance memory _locked = locked[_tokenId];
//     assert(_value > 0); // dev: need non-zero value
//     require(_locked.amount > 0, "No existing lock found");
//     require(_locked.end > block.timestamp, "Cannot add to expired lock.");
//     _depositFor(
//         _tokenId,
//         _value,
//         0,
//         _locked,
//         DepositType.INCREASE_LOCK_AMOUNT
//     );
// }
// /// @notice Extend the unlock time for `_tokenId`
// /// @param _lockDuration New number of seconds until tokens unlock
// function increaseUnlockTime(
//     uint256 _tokenId,
//     uint256 _lockDuration
// ) external nonReentrant {
//     require(
//         _isAuthorized(ownerOf(_tokenId), msg.sender, _tokenId),
//         "caller is not owner nor approved"
//     );
//     LockedBalance memory _locked = locked[_tokenId];
//     uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks
//     require(_locked.end > block.timestamp, "Lock expired");
//     require(_locked.amount > 0, "Nothing is locked");
//     require(unlockTime > _locked.end, "Can only increase lock duration");
//     require(
//         unlockTime <= block.timestamp + MAXTIME,
//         "Voting lock can be 4 years max"
//     );
//     require(
//         unlockTime <= _locked.start + MAXTIME,
//         "Voting lock can be 4 years max"
//     );
//     _depositFor(
//         _tokenId,
//         0,
//         unlockTime,
//         _locked,
//         DepositType.INCREASE_UNLOCK_TIME
//     );
// }
// /// @notice Withdraw all tokens for `_tokenId`
// /// @dev Only possible if the lock has expired
// function withdraw(uint256 _tokenId) public virtual nonReentrant {
//     require(
//         _isAuthorized(ownerOf(_tokenId), msg.sender, _tokenId),
//         "caller is not owner nor approved"
//     );
//     LockedBalance memory _locked = locked[_tokenId];
//     require(block.timestamp >= _locked.end, "The lock didn't expire");
//     uint256 value = uint256(int256(_locked.amount));
//     locked[_tokenId] = LockedBalance(0, 0, 0, 0);
//     uint256 supplyBefore = supply;
//     supply = supplyBefore - value;
//     assert(underlying.transfer(msg.sender, value));
//     // Burn the NFT
//     _burn(_tokenId);
//     emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
//     emit Supply(supplyBefore, supplyBefore - value);
// }
// function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
//     uint256 nftCount = _tokenIds.length;
//     for (uint i = 0; i < nftCount; ) {
//         withdraw(_tokenIds[i]);
//         unchecked {
//             ++i;
//         }
//     }
// }
// function withdraw(address _user) external nonReentrant {
//     uint256 nftCount = balanceOf(_user);
//     for (uint i = 0; i < nftCount; ) {
//         uint256 tokenId_ = tokenOfOwnerByIndex(_user, i);
//         withdraw(tokenId_);
//         unchecked {
//             ++i;
//         }
//     }
// }
// /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
// /// @param _value Amount to deposit
// /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
// /// @param _to Address to deposit
// /// @param _stakeNFT should we stake into the staking contract
// function _createLock(
//     uint256 _value,
//     uint256 _lockDuration,
//     address _to,
//     bool _stakeNFT
// ) internal returns (uint256) {
//     uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks
//     require(_value > 0, "value = 0"); // dev: need non-zero value
//     require(unlockTime > block.timestamp, "Can only lock in the future");
//     require(
//         unlockTime <= block.timestamp + MAXTIME,
//         "Voting lock can be 4 years max"
//     );
//     ++tokenId;
//     uint256 _tokenId = tokenId;
//     _depositFor(
//         _tokenId,
//         _value,
//         unlockTime,
//         locked[_tokenId],
//         DepositType.CREATE_LOCK_TYPE
//     );
//     // if the user wants to stake the NFT then we mint to the contract and
//     // stake on behalf of the user
//     if (_stakeNFT) {
//         _mint(address(this), _tokenId);
//         bytes memory data = abi.encode(_stakeNFT, _to, _lockDuration);
//         this.safeTransferFrom(
//             address(this),
//             address(staking),
//             _tokenId,
//             data
//         );
//     } else _mint(_to, _tokenId);
//     return _tokenId;
// }
// function balanceOfNFT(uint256 _tokenId) public view returns (uint256) {
//     return locked[_tokenId].power;
// }
// function tokenURI(
//     uint256
// ) public view virtual override returns (string memory) {
//     // todo
//     return "";
// }
}
