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

import {IAggregatorV3Interface} from "../../../interfaces/governance/IAggregatorV3Interface.sol";
import {ILPOracle} from "../../../interfaces/governance/ILPOracle.sol";
import {ILocker} from "../../../interfaces/governance/ILocker.sol";
import {IMultiTokenRewards, IOmnichainStaking} from "../../../interfaces/governance/IOmnichainStaking.sol";
import {IPoolVoter} from "../../../interfaces/governance/IPoolVoter.sol";
import {IWETH} from "../../../interfaces/governance/IWETH.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20VotesUpgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title OmnichainStaking
 * @dev An omnichain staking contract that allows users to stake their veNFT
 * and get some voting power. Once staked, the voting power is available cross-chain.
 */
abstract contract OmnichainStakingBase is
  IOmnichainStaking,
  ERC20VotesUpgradeable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable
{
  using SafeERC20 for IERC20;

  ILocker public locker;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => mapping(address who => uint256 rewards)) public rewards;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => mapping(address who => uint256)) public userRewardPerTokenPaid;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => uint256) public lastUpdateTime;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => uint256) public periodFinish;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => uint256) public rewardPerTokenStored;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => uint256) public rewardRate;

  /// @inheritdoc IMultiTokenRewards
  uint256 public rewardsDuration;

  /// @inheritdoc IMultiTokenRewards
  IERC20 public rewardToken1;

  /// @inheritdoc IMultiTokenRewards
  IERC20 public rewardToken2;

  IERC20 public weth;

  // used to keep track of voting powers for each nft id
  mapping(uint256 => uint256) public power;

  // used to keep track of ownership of token lockers
  mapping(uint256 => address) public lockedByToken;
  mapping(address => uint256[]) public lockedTokenIdNfts;

  /// @notice Account that distributes staking rewards
  address public distributor;

  /**
   * @dev Initializes the contract with the provided token lockers.
   * @param _locker The address of the token locker contract.
   */
  function __OmnichainStakingBase_init(
    string memory name,
    string memory symbol,
    address _locker,
    address _weth,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration,
    address _distributor
  ) internal {
    __ERC20Votes_init();
    __Ownable_init(msg.sender);
    __ReentrancyGuard_init();
    __ERC20_init(name, symbol);

    locker = ILocker(_locker);
    weth = IERC20(_weth);
    rewardToken1 = IERC20(_rewardToken1);
    rewardToken2 = IERC20(_rewardToken2);
    rewardsDuration = _rewardsDuration;

    // give approvals for increase lock functions
    locker.underlying().approve(_locker, type(uint256).max);

    distributor = _distributor;
  }

  /**
   * @dev Receives an ERC721 token from the lockers and grants voting power accordingly.
   * @param from The address sending the ERC721 token.
   * @param tokenId The ID of the ERC721 token.
   * @param data Additional data.
   * @return ERC721 onERC721Received selector.
   */
  function _onERC721ReceivedInternal(
    address,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) internal returns (bytes4) {
    require(msg.sender == address(locker), "only locker");

    if (data.length > 0) {
      (, from,) = abi.decode(data, (bool, address, uint256));
    }

    _updateRewardDual(rewardToken1, rewardToken2, from);

    // track nft id
    lockedByToken[tokenId] = from;
    lockedTokenIdNfts[from].push(tokenId);

    // set delegate if not set already
    if (delegates(from) == address(0)) _delegate(from, from);

    // mint voting power
    power[tokenId] = _getTokenPower(locker.balanceOfNFT(tokenId));
    _mint(from, power[tokenId]);

    return this.onERC721Received.selector;
  }

  /**
   * @dev Gets the details of locked NFTs for a given user.
   * @param _user The address of the user.
   * @return lockedTokenIds The array of locked NFT IDs.
   * @return tokenDetails The array of locked NFT details.
   */
  function getLockedNftDetails(address _user) external view returns (uint256[] memory, ILocker.LockedBalance[] memory) {
    uint256 tokenIdsLength = lockedTokenIdNfts[_user].length;
    uint256[] memory lockedTokenIds = lockedTokenIdNfts[_user];

    uint256[] memory tokenIds = new uint256[](tokenIdsLength);
    ILocker.LockedBalance[] memory tokenDetails = new ILocker.LockedBalance[](tokenIdsLength);

    for (uint256 i; i < tokenIdsLength;) {
      tokenDetails[i] = locker.locked(lockedTokenIds[i]);
      tokenIds[i] = lockedTokenIds[i];

      unchecked {
        ++i;
      }
    }

    return (tokenIds, tokenDetails);
  }

  function onERC721Received(address to, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
    return _onERC721ReceivedInternal(to, from, tokenId, data);
  }

  /**
   * @dev Unstakes a regular token NFT and transfers it back to the user.
   * @param tokenId The ID of the regular token NFT to unstake.
   */
  function unstakeToken(uint256 tokenId) external {
    _updateRewardDual(rewardToken1, rewardToken2, msg.sender);
    require(lockedByToken[tokenId] != address(0), "!tokenId");
    address lockedBy_ = lockedByToken[tokenId];
    if (_msgSender() != lockedBy_) {
      revert InvalidUnstaker(_msgSender(), lockedBy_);
    }

    delete lockedByToken[tokenId];
    lockedTokenIdNfts[_msgSender()] = _deleteAnElement(lockedTokenIdNfts[_msgSender()], tokenId);

    // reset and burn voting power
    _burn(msg.sender, power[tokenId]);
    power[tokenId] = 0;

    locker.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /**
   * @dev Updates the lock duration for a specific NFT.
   * @param tokenId The ID of the NFT for which to update the lock duration.
   * @param newLockDuration The new lock duration in seconds.
   */
  function increaseLockDuration(uint256 tokenId, uint256 newLockDuration) external {
    require(newLockDuration > 0, "!newLockAmount");

    require(msg.sender == lockedByToken[tokenId], "!tokenId");
    locker.increaseUnlockTime(tokenId, newLockDuration);

    // update voting power
    _burn(msg.sender, power[tokenId]);
    power[tokenId] = _getTokenPower(locker.balanceOfNFT(tokenId));
    _mint(msg.sender, power[tokenId]);
  }

  /**
   * @dev Updates the lock amount for a specific NFT.
   * @param tokenId The ID of the NFT for which to update the lock amount.
   * @param newLockAmount The new lock amount in tokens.
   */
  function increaseLockAmount(uint256 tokenId, uint256 newLockAmount) external {
    require(newLockAmount > 0, "!newLockAmount");

    require(msg.sender == lockedByToken[tokenId], "!tokenId");
    locker.underlying().transferFrom(msg.sender, address(this), newLockAmount);
    locker.increaseAmount(tokenId, newLockAmount);

    // update voting power
    _burn(msg.sender, power[tokenId]);
    power[tokenId] = _getTokenPower(locker.balanceOfNFT(tokenId));
    _mint(msg.sender, power[tokenId]);
  }

  /**
   * Returns how much max voting power this locker will give out for the
   * given amount of tokens. This varies for the instance of locker.
   *
   * @param amount The amount of tokens to give voting power for.
   */
  function getTokenPower(uint256 amount) external view returns (uint256 _power) {
    _power = _getTokenPower(amount);
  }

  /// @inheritdoc IMultiTokenRewards
  function earned(IERC20 token, address account) public view returns (uint256) {
    return _earned(token, account);
  }

  /// @inheritdoc IMultiTokenRewards
  function lastTimeRewardApplicable(IERC20 token) public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish[token]);
  }

  function totalNFTStaked(address who) public view returns (uint256) {
    return lockedTokenIdNfts[who].length;
  }

  /// @inheritdoc IMultiTokenRewards
  function rewardPerToken(IERC20 token) external view returns (uint256) {
    return _rewardPerToken(token);
  }

  /// @inheritdoc IMultiTokenRewards
  function notifyRewardAmount(IERC20 token, uint256 reward) external {
    require(msg.sender == distributor, "!distributor");
    _updateReward(token, address(0));

    token.transferFrom(msg.sender, address(this), reward);

    if (block.timestamp >= periodFinish[token]) {
      // If no reward is currently being distributed, the new rate is just `reward / duration`
      rewardRate[token] = reward / rewardsDuration;
    } else {
      // Otherwise, cancel the future reward and add the amount left to distribute to reward
      uint256 remaining = periodFinish[token] - block.timestamp;
      uint256 leftover = remaining * rewardRate[token];
      rewardRate[token] = (reward + leftover) / rewardsDuration;
    }

    // Ensures the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of `rewardRate` in the earned and `rewardsPerToken` functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = token.balanceOf(address(this));
    require(rewardRate[token] <= balance / rewardsDuration, "not enough balance");

    lastUpdateTime[token] = block.timestamp;
    periodFinish[token] = block.timestamp + rewardsDuration; // Change the duration
    emit RewardAdded(token, reward, msg.sender);
  }

  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  /**
   * Admin only function to set the rewards distributor
   *
   * @param what The new address for the rewards distributor
   */
  function setRewardDistributor(address what) external onlyOwner {
    distributor = what;
  }

  /**
   * Temporary fix to init the delegate variable for a given user. This is
   * an admin only function as it's a temporary fix. This can be permissionless.
   *
   * @param who The who for whom delegate should be called.
   */
  function initDelegates(address[] memory who) external {
    for (uint256 i = 0; i < who.length; i++) {
      require(delegates(who[i]) == address(0), "delegate already set");
      _delegate(who[i], who[i]);
    }
  }

  /// @inheritdoc IMultiTokenRewards
  function getReward(address who, IERC20 token) public nonReentrant {
    _updateReward(token, who);
    uint256 reward = rewards[token][who];
    if (reward > 0) {
      rewards[token][who] = 0;
      token.safeTransfer(who, reward);
      emit RewardClaimed(token, reward, who, msg.sender);
    }
  }

  /// @inheritdoc IMultiTokenRewards
  function updateRewards(IERC20 token, address who) external {
    _updateReward(token, who);
  }

  /**
   * @dev This is an ETH variant of the get rewards function. It unwraps the token and sends out
   * raw ETH to the user.
   */
  function getRewardETH(address who) public nonReentrant {
    _updateReward(weth, who);
    uint256 reward = rewards[weth][who];
    if (reward > 0) {
      rewards[weth][who] = 0;
      IWETH(address(weth)).withdraw(reward);
      (bool ethSendSuccess,) = who.call{value: reward}("");
      require(ethSendSuccess, "eth send failed");
      emit RewardClaimed(weth, reward, who, msg.sender);
    }
  }

  /**
   * @dev Prevents transfers of voting power.
   */
  function transfer(address, uint256) public pure override returns (bool) {
    revert("transfer disabled");
  }

  /**
   * @dev Prevents transfers of voting power.
   */
  function transferFrom(address, address, uint256) public pure override returns (bool) {
    revert("transferFrom disabled");
  }

  /**
   * @dev Deletes an element from an array.
   * @param elements The array to delete from.
   * @param element The element to delete.
   * @return The updated array.
   */
  function _deleteAnElement(uint256[] memory elements, uint256 element) internal pure returns (uint256[] memory) {
    uint256 length = elements.length;
    uint256 count;

    for (uint256 i = 0; i < length; i++) {
      if (elements[i] != element) {
        count++;
      }
    }

    uint256[] memory updatedArray = new uint256[](count);
    uint256 index;

    for (uint256 i = 0; i < length; i++) {
      if (elements[i] != element) {
        updatedArray[index] = elements[i];
        index++;
      }
    }

    return updatedArray;
  }

  function _getTokenPower(uint256 amount) internal view virtual returns (uint256 power);

  function totalVotes() external view returns (uint256) {
    return totalSupply();
  }

  /**
   * @notice Called frequently to update the staking parameters associated to an address
   * @param token The token for which the rewards are updated
   * @param account The account for which the rewards are updated
   */
  function _updateReward(IERC20 token, address account) internal {
    rewardPerTokenStored[token] = _rewardPerToken(token);
    lastUpdateTime[token] = lastTimeRewardApplicable(token);

    if (account != address(0)) {
      rewards[token][account] = _earned(token, account);
      userRewardPerTokenPaid[token][account] = rewardPerTokenStored[token];
    }
  }

  /**
   * @notice Called frequently to update the staking parameters associated to an address
   * @param token1 The first token for which the rewards are updated
   * @param token2 The second token for which the rewards are updated
   * @param account The account for which the rewards are updated
   */
  function _updateRewardDual(IERC20 token1, IERC20 token2, address account) internal {
    rewardPerTokenStored[token1] = _rewardPerToken(token1);
    lastUpdateTime[token1] = lastTimeRewardApplicable(token1);
    rewardPerTokenStored[token2] = _rewardPerToken(token2);
    lastUpdateTime[token2] = lastTimeRewardApplicable(token2);

    if (account != address(0)) {
      rewards[token1][account] = _earned(token1, account);
      rewards[token2][account] = _earned(token2, account);
      userRewardPerTokenPaid[token1][account] = rewardPerTokenStored[token1];
      userRewardPerTokenPaid[token2][account] = rewardPerTokenStored[token2];
    }
  }

  /**
   * @notice Computes the amount earned by an account
   * @dev Takes into account the boosted balance and the boosted total supply
   * @param token_ The token for which the rewards are computed
   * @param account_ The account for which the rewards are computed
   */
  function _earned(IERC20 token_, address account_) internal view returns (uint256) {
    return (balanceOf(account_) * (_rewardPerToken(token_) - userRewardPerTokenPaid[token_][account_])) / 1e18
      + rewards[token_][account_];
  }

  function _rewardPerToken(IERC20 _token) internal view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored[_token];
    }
    return rewardPerTokenStored[_token]
      + (((lastTimeRewardApplicable(_token) - lastUpdateTime[_token]) * rewardRate[_token] * 1e18) / totalSupply());
  }
}
