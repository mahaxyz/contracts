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

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import {IMultiStakingRewardsERC4626} from "../../interfaces/core/IMultiStakingRewardsERC4626.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title ERC4262 Staking Rewards
/// @author Forked form SetProtocol
/// https://github.com/SetProtocol/index-coop-contracts/blob/master/contracts/staking/StakingRewards.sol
/// @notice The `MultiStakingRewardsERC4626` contracts allows to stake an ERC20 token and receieve multiple other ERC20
/// rewards
/// @dev This contracts is designed to be used via a proxy and follows the ERC4626 standard.
/// @dev This contracts needs at least two reward tokens to be used
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
  mapping(IERC20 reward => mapping(address who => uint256))
    public userRewardPerTokenPaid;

  /// @inheritdoc IMultiStakingRewardsERC4626
  mapping(IERC20 reward => mapping(address who => uint256 rewards))
    public rewards;

  /// @inheritdoc IMultiStakingRewardsERC4626
  IERC20 public rewardToken1;

  /// @inheritdoc IMultiStakingRewardsERC4626
  IERC20 public rewardToken2;

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
  ) internal onlyInitializing {
    __ERC20_init(name, symbol);
    __ERC4626_init_unchained(IERC20(_stakingToken));
    __AccessControlEnumerable_init();

    require(_rewardToken1 != address(0), "reward token 1 is 0x0");
    require(_rewardToken2 != address(0), "reward token 2 is 0x0");

    // We are not checking the compatibility of the reward token between the distributor and this contract here
    // because it is checked by the `RewardsDistributor` when activating the staking contract
    // Parameters
    rewardsDuration = _rewardsDuration;
    rewardToken1 = IERC20(_rewardToken1);
    rewardToken2 = IERC20(_rewardToken2);

    _grantRole(DEFAULT_ADMIN_ROLE, _governance);
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function lastTimeRewardApplicable(
    IERC20 token
  ) public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish[token]);
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function rewardPerToken(IERC20 token) public view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored[token];
    }
    return
      rewardPerTokenStored[token] +
      (((lastTimeRewardApplicable(token) - lastUpdateTime[token]) *
        rewardRate[token] *
        1e18) / totalSupply());
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function earned(IERC20 token, address account) public view returns (uint256) {
    return _earned(token, account, balanceOf(account));
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function approveUnderlyingWithPermit(
    uint256 val,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    IERC20Permit(asset()).permit(
      msg.sender,
      address(this),
      val,
      deadline,
      v,
      r,
      s
    );
  }

  /// @inheritdoc ERC4626Upgradeable
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    _updateRewardDual(rewardToken1, rewardToken2, caller);

    // continues the call to the erc4626 withdraw
    super._withdraw(caller, receiver, owner, assets, shares);
  }

  /// @inheritdoc ERC4626Upgradeable
  function _deposit(
    address caller,
    address receiver,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    _updateRewardDual(rewardToken1, rewardToken2, caller);

    // continues the call to the erc4626 deposit
    super._deposit(caller, receiver, assets, shares);
  }

  function _earned(
    IERC20 token,
    address account,
    uint256 balance
  ) internal view returns (uint256) {
    return
      (balance *
        (rewardPerToken(token) - userRewardPerTokenPaid[token][account])) /
      1e18 +
      rewards[token][account];
  }

  function _boostedBalance(
    address account,
    uint256 balance
  ) internal view returns (uint256) {
    // todo add staking boost
    return balance;
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

  function _updateRewardDual(
    IERC20 token1,
    IERC20 token2,
    address account
  ) internal {
    rewardPerTokenStored[token1] = rewardPerToken(token1);
    lastUpdateTime[token1] = lastTimeRewardApplicable(token1);
    rewardPerTokenStored[token2] = rewardPerToken(token2);
    lastUpdateTime[token2] = lastTimeRewardApplicable(token2);

    if (account != address(0)) {
      uint256 bal = balanceOf(account);
      rewards[token1][account] = _earned(token1, account, bal);
      rewards[token2][account] = _earned(token2, account, bal);
      userRewardPerTokenPaid[token1][account] = rewardPerTokenStored[token1];
      userRewardPerTokenPaid[token2][account] = rewardPerTokenStored[token2];
    }
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function getReward(address who, IERC20 token) public nonReentrant {
    _updateReward(token, who);
    uint256 reward = rewards[token][who];
    if (reward > 0) {
      rewards[token][who] = 0;
      token.safeTransfer(who, reward);
      emit RewardClaimed(token, reward, who, msg.sender);
    }
  }

  /// @inheritdoc IMultiStakingRewardsERC4626
  function notifyRewardAmount(
    IERC20 token,
    uint256 reward
  ) external onlyRole(DISTRIBUTOR_ROLE) nonReentrant {
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
    require(
      rewardRate[token] <= balance / rewardsDuration,
      "not enough balance"
    );

    lastUpdateTime[token] = block.timestamp;
    periodFinish[token] = block.timestamp + rewardsDuration; // Change the duration
    emit RewardAdded(token, reward, msg.sender);
  }
}
