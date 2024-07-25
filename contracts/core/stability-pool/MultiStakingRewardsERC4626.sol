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
import {
  ERC4626Upgradeable, IERC20
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import {IMultiStakingRewardsERC4626} from "../../interfaces/core/IMultiStakingRewardsERC4626.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title StakingRewards
/// @author Forked form SetProtocol
/// https://github.com/SetProtocol/index-coop-contracts/blob/master/contracts/staking/StakingRewards.sol
/// @notice The `StakingRewards` contracts allows to stake an ERC20 token to receive as reward another ERC20
/// @dev This contracts is managed by the reward distributor and implements the staking interface
contract MultiStakingRewardsERC4626 is
  AccessControlEnumerableUpgradeable,
  ERC4626Upgradeable,
  ReentrancyGuardUpgradeable,
  MulticallUpgradeable,
  IMultiStakingRewardsERC4626
{
  using SafeERC20 for IERC20;

  /// @inheritdoc IMultiStakingRewardsERC4626
  bytes32 public DISTRIBUTOR_ROLE;

  /// @inheritdoc IMultiStakingRewardsERC4626
  mapping(IERC20 reward => uint256) public periodFinish;

  /// @inheritdoc IMultiStakingRewardsERC4626
  mapping(IERC20 reward => uint256) public rewardRate;

  /// @inheritdoc IMultiStakingRewardsERC4626
  uint256 public rewardsDuration;

  /// @inheritdoc IMultiStakingRewardsERC4626
  mapping(IERC20 reward => uint256) public lastUpdateTime;

  /// @inheritdoc IMultiStakingRewardsERC4626
  mapping(IERC20 reward => uint256) public rewardPerTokenStored;

  /// @inheritdoc IMultiStakingRewardsERC4626
  mapping(IERC20 reward => mapping(address who => uint256)) public userRewardPerTokenPaid;

  /// @inheritdoc IMultiStakingRewardsERC4626
  mapping(IERC20 reward => mapping(address who => uint256 rewards)) public rewards;

  /// @inheritdoc IMultiStakingRewardsERC4626
  IERC20 public rewardToken1;

  /// @inheritdoc IMultiStakingRewardsERC4626
  IERC20 public rewardToken2;

  // ============================ Constructor ====================================

  /// @notice Initializes the staking contract with a first set of parameters
  /// @param _rewardToken1 First ERC20 token given as reward
  /// @param _rewardToken2 Second ERC20 token given as reward
  /// @param _rewardsDuration Duration of the staking contract
  function __MultiStakingRewardsERC4626_init(
    string memory name,
    string memory symbol,
    address _stakingToken,
    address _governance,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration
  ) internal {
    __ERC20_init(name, symbol);
    __ERC4626_init_unchained(IERC20(_stakingToken));
    __AccessControlEnumerable_init();

    // We are not checking the compatibility of the reward token between the distributor and this contract here
    // because it is checked by the `RewardsDistributor` when activating the staking contract
    // Parameters
    rewardsDuration = _rewardsDuration;
    rewardToken1 = IERC20(_rewardToken1);
    rewardToken2 = IERC20(_rewardToken2);

    DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    _grantRole(DEFAULT_ADMIN_ROLE, _governance);
  }

  // ============================ Modifiers ======================================

  /// @notice Checks to see if the calling address is the zero address
  /// @param account Address to check
  modifier zeroCheck(address account) {
    require(account != address(0), "0");
    _;
  }

  /// @notice Called frequently to update the staking parameters associated to an address
  /// @param account Address of the account to update
  function _updateReward(IERC20 token, address account) internal {
    rewardPerTokenStored[token] = rewardPerToken(token);
    lastUpdateTime[token] = lastTimeRewardApplicable(token);
    if (account != address(0)) {
      rewards[token][account] = earned(token, account);
      userRewardPerTokenPaid[token][account] = rewardPerTokenStored[token];
    }
  }

  // ============================ View functions =================================

  /// @inheritdoc IMultiStakingRewardsERC4626
  function lastTimeRewardApplicable(IERC20 token) public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish[token]);
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function rewardPerToken(IERC20 token) public view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored[token];
    }
    return rewardPerTokenStored[token]
      + (((lastTimeRewardApplicable(token) - lastUpdateTime[token]) * rewardRate[token] * 1e18) / totalSupply());
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function earned(IERC20 token, address account) public view returns (uint256) {
    return (balanceOf(account) * (rewardPerToken(token) - userRewardPerTokenPaid[token][account])) / 1e18
      + rewards[token][account];
  }

  // ======================== Mutative functions forked ==========================

  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    _updateReward(rewardToken1, owner);
    _updateReward(rewardToken2, owner);
    super._withdraw(caller, receiver, owner, assets, shares);
  }

  function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
    _updateReward(rewardToken1, caller);
    _updateReward(rewardToken2, caller);
    super._deposit(caller, receiver, assets, shares);
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function getReward(address who, IERC20 token) public nonReentrant {
    _updateReward(token, who);
    uint256 reward = rewards[token][who];
    if (reward > 0) {
      rewards[token][who] = 0;
      token.safeTransfer(who, reward);
      // emit RewardPaid(msg.sender, reward);
    }
  }

  // ====================== Restricted Functions =================================

  /// @inheritdoc IMultiStakingRewardsERC4626
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
    require(rewardRate[token] <= balance / rewardsDuration, "91");

    lastUpdateTime[token] = block.timestamp;
    periodFinish[token] = block.timestamp + rewardsDuration; // Change the duration
      // emit RewardAdded(reward);
  }
}
