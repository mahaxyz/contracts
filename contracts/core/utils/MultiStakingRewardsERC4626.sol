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

import {AccessControlEnumerableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import {IMultiStakingRewardsERC4626, IMultiTokenRewards} from "../../interfaces/core/IMultiStakingRewardsERC4626.sol";
import {IOmnichainStaking} from "../../interfaces/governance/IOmnichainStaking.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ERC4262 Staking Rewards
 * @author maha.xyz
 * @dev Forked form SetProtocol
 * @notice The `MultiStakingRewardsERC4626` contracts allows to stake an ERC20 token and
 * receieve multiple other ERC20 rewards.
 * https://github.com/SetProtocol/index-coop-contracts/blob/master/contracts/staking/StakingRewards.sol
 * @dev This contracts is designed to be used via a proxy and follows the ERC4626 standard.
 * @dev This contracts needs at least two reward tokens to be used
 */
abstract contract MultiStakingRewardsERC4626 is
  AccessControlEnumerableUpgradeable,
  ERC4626Upgradeable,
  ReentrancyGuardUpgradeable,
  MulticallUpgradeable,
  IMultiStakingRewardsERC4626
{
  using SafeERC20 for IERC20;

  /// @inheritdoc IMultiStakingRewardsERC4626
  bytes32 public immutable DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => uint256) public periodFinish;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => uint256) public rewardRate;

  /// @inheritdoc IMultiTokenRewards
  uint256 public rewardsDuration;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => uint256) public lastUpdateTime;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => uint256) public rewardPerTokenStored;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => mapping(address who => uint256)) public userRewardPerTokenPaid;

  /// @inheritdoc IMultiTokenRewards
  mapping(IERC20 reward => mapping(address who => uint256 rewards)) public rewards;

  /// @inheritdoc IMultiTokenRewards
  IERC20 public rewardToken1;

  /// @inheritdoc IMultiTokenRewards
  IERC20 public rewardToken2;

  /// @inheritdoc IMultiStakingRewardsERC4626
  IOmnichainStaking public staking;

  /// @dev Boosted total supply that is used to compute the rewards
  uint256 internal _boostedTotalSupply;

  /// @dev Total voting power of all the depositors
  uint256 internal _totalVotingPower;

  /// @dev Voting power of a depositor
  mapping(address who => uint256 votingPower) internal _votingPower;

  /// @dev Boosted balances that are used to compute the rewards
  mapping(address who => uint256 boostedBalance) internal _boostedBalances;

  /// @notice Initializes the staking contract with a first set of parameters
  function __MultiStakingRewardsERC4626_init(
    string memory name,
    string memory symbol,
    address _stakingToken,
    address _governance,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration,
    address _staking
  ) internal onlyInitializing {
    __ERC20_init(name, symbol);
    __ERC4626_init(IERC20(_stakingToken));
    __AccessControlEnumerable_init();

    require(_rewardToken1 != address(0), "reward token 1 is 0x0");
    require(_rewardToken2 != address(0), "reward token 2 is 0x0");

    // We are not checking the compatibility of the reward token between the distributor and this contract here
    // because it is checked by the `RewardsDistributor` when activating the staking contract
    // Parameters
    rewardsDuration = _rewardsDuration;
    rewardToken1 = IERC20(_rewardToken1);
    rewardToken2 = IERC20(_rewardToken2);
    staking = IOmnichainStaking(_staking);

    _grantRole(DEFAULT_ADMIN_ROLE, _governance);

    if (_boostedTotalSupply == 0) {
      _boostedTotalSupply = totalSupply();
    }

    // register the erc20 event
    _mint(msg.sender, 1e18);
    _burn(msg.sender, 1e18);
  }

  /// @inheritdoc IMultiTokenRewards
  function lastTimeRewardApplicable(IERC20 token) public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish[token]);
  }

  /// @inheritdoc IMultiTokenRewards
  function rewardPerToken(IERC20 token) external view returns (uint256) {
    return _rewardPerToken(token, _boostedTotalSupply);
  }

  /// @inheritdoc IMultiTokenRewards
  function earned(IERC20 token, address account) public view returns (uint256) {
    (uint256 boostedBalance_, uint256 boostedTotalSupply_) = _calculateBoostedBalance(account);
    return _earned(token, account, boostedBalance_, boostedTotalSupply_);
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function totalBoostedSupply() external view returns (uint256 boostedTotalSupply_) {
    (, boostedTotalSupply_) = _calculateBoostedBalance(address(0));
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function boostedBalance(address who) external view returns (uint256 boostedBalance_) {
    (boostedBalance_,) = _calculateBoostedBalance(who);
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function totalVotingPower() external view returns (uint256 supply) {
    (, supply) = _getVotingPower(address(0));
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function votingPower(address who) external view returns (uint256 balance) {
    (balance,) = _getVotingPower(who);
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function approveUnderlyingWithPermit(uint256 val, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    IERC20Permit(asset()).permit(msg.sender, address(this), val, deadline, v, r, s);
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
  function getRewardDual(address who) public nonReentrant {
    _updateRewardDual(rewardToken1, rewardToken2, who);

    uint256 reward1 = rewards[rewardToken1][who];
    if (reward1 > 0) {
      rewards[rewardToken1][who] = 0;
      rewardToken1.safeTransfer(who, reward1);
      emit RewardClaimed(rewardToken1, reward1, who, msg.sender);
    }

    uint256 reward2 = rewards[rewardToken2][who];
    if (reward2 > 0) {
      rewards[rewardToken2][who] = 0;
      rewardToken2.safeTransfer(who, reward2);
      emit RewardClaimed(rewardToken2, reward2, who, msg.sender);
    }
  }

  /// @inheritdoc IMultiTokenRewards
  function notifyRewardAmount(IERC20 token, uint256 reward) external onlyRole(DISTRIBUTOR_ROLE) nonReentrant {
    _updateReward(token, address(0));
    token.safeTransferFrom(msg.sender, address(this), reward);

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

  /// @inheritdoc IMultiTokenRewards
  function updateRewards(IERC20 token, address who) external {
    _updateReward(token, who);
  }

  function _rewardPerToken(IERC20 _token, uint256 boostedTotalSupply_) internal view returns (uint256) {
    if (boostedTotalSupply_ == 0) {
      return rewardPerTokenStored[_token];
    }
    return rewardPerTokenStored[_token]
      + (((lastTimeRewardApplicable(_token) - lastUpdateTime[_token]) * rewardRate[_token] * 1e18) / boostedTotalSupply_);
  }

  /// @inheritdoc ERC4626Upgradeable
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    _updateRewardDual(rewardToken1, rewardToken2, owner);
    super._withdraw(caller, receiver, owner, assets, shares);
  }

  /// @inheritdoc ERC4626Upgradeable
  function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
    _updateRewardDual(rewardToken1, rewardToken2, receiver);
    super._deposit(caller, receiver, assets, shares);
  }

  /**
   * @notice Computes the amount earned by an account
   * @dev Takes into account the boosted balance and the boosted total supply
   * @param token_ The token for which the rewards are computed
   * @param account_ The account for which the rewards are computed
   * @param boostedBalance_ The boosted balance of the account
   * @param boostedTotalSupply_ The boosted total supply
   */
  function _earned(
    IERC20 token_,
    address account_,
    uint256 boostedBalance_,
    uint256 boostedTotalSupply_
  ) internal view returns (uint256) {
    return (boostedBalance_ * (_rewardPerToken(token_, boostedTotalSupply_) - userRewardPerTokenPaid[token_][account_]))
      / 1e18 + rewards[token_][account_];
  }

  /**
   * @notice Called frequently to update the staking parameters associated to an address
   * @param token The token for which the rewards are updated
   * @param account The account for which the rewards are updated
   */
  function _updateReward(IERC20 token, address account) internal {
    _updatingVotingPower(account);

    (uint256 boostedBalance_, uint256 boostedTotalSupply_) = _calculateBoostedBalance(account);
    _boostedTotalSupply = boostedTotalSupply_;

    rewardPerTokenStored[token] = _rewardPerToken(token, boostedTotalSupply_);
    lastUpdateTime[token] = lastTimeRewardApplicable(token);

    if (account != address(0)) {
      _boostedBalances[account] = boostedBalance_;
      rewards[token][account] = _earned(token, account, boostedBalance_, boostedTotalSupply_);
      userRewardPerTokenPaid[token][account] = rewardPerTokenStored[token];

      emit UpdatedBoost(account, boostedBalance_, boostedTotalSupply_);
    }
  }

  /**
   * @notice Called frequently to update the staking parameters associated to an address
   * @param token1 The first token for which the rewards are updated
   * @param token2 The second token for which the rewards are updated
   * @param account The account for which the rewards are updated
   */
  function _updateRewardDual(IERC20 token1, IERC20 token2, address account) internal {
    _updatingVotingPower(account);

    (uint256 boostedBalance_, uint256 boostedTotalSupply_) = _calculateBoostedBalance(account);
    _boostedTotalSupply = boostedTotalSupply_;

    rewardPerTokenStored[token1] = _rewardPerToken(token1, boostedTotalSupply_);
    lastUpdateTime[token1] = lastTimeRewardApplicable(token1);
    rewardPerTokenStored[token2] = _rewardPerToken(token2, boostedTotalSupply_);
    lastUpdateTime[token2] = lastTimeRewardApplicable(token2);

    if (account != address(0)) {
      _boostedBalances[account] = boostedBalance_;

      rewards[token1][account] = _earned(token1, account, boostedBalance_, boostedTotalSupply_);
      rewards[token2][account] = _earned(token2, account, boostedBalance_, boostedTotalSupply_);
      userRewardPerTokenPaid[token1][account] = rewardPerTokenStored[token1];
      userRewardPerTokenPaid[token2][account] = rewardPerTokenStored[token2];

      emit UpdatedBoost(account, boostedBalance_, boostedTotalSupply_);
    }
  }

  /**
   * @notice Updates the voting power of an account
   * @param account The account for which the voting power is updated
   */
  function _updatingVotingPower(address account) internal {
    (uint256 votingBalance, uint256 votingTotal) = _getVotingPower(account);
    _votingPower[account] = votingBalance;
    _totalVotingPower = votingTotal;
  }

  /**
   * @notice Computes the boosted balance and the boosted total supply of an account
   * @param account The account for which the boosted balance and the boosted total supply are computed
   * @return boostedBalance_ The boosted balance of the account
   * @return boostedTotalSupply_ The boosted total supply
   */
  function _calculateBoostedBalance(address account)
    internal
    view
    returns (uint256 boostedBalance_, uint256 boostedTotalSupply_)
  {
    uint256 balance = balanceOf(account);
    uint256 totalSupply = totalSupply();

    if (staking == IOmnichainStaking(address(0))) {
      return (balance / 5, totalSupply / 5);
    }

    boostedBalance_ = balance / 5;
    if (_totalVotingPower > 0) {
      boostedBalance_ += (totalSupply * _votingPower[account] / _totalVotingPower) * 4 / 5;
    }

    boostedBalance_ = Math.min(balance, boostedBalance_);
    boostedTotalSupply_ = _boostedTotalSupply + boostedBalance_ - _boostedBalances[account];
    return (boostedBalance_, boostedTotalSupply_);
  }

  /**
   * @notice Computes the voting power of an account
   * @param account The account for which the voting power is requested
   * @return votingBalance The voting power of the account
   * @return votingTotal The total voting power
   */
  function _getVotingPower(address account) internal view returns (uint256 votingBalance, uint256 votingTotal) {
    if (account == address(0) || address(staking) == address(0)) return (0, _totalVotingPower);
    votingBalance = staking.getVotes(account);
    votingTotal = _totalVotingPower + votingBalance - _votingPower[account];
  }
}
