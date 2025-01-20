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

import {ILocker} from "../../governance/locker/BaseLocker.sol";
import {OmnichainStakingToken} from "../../governance/locker/staking/OmnichainStakingToken.sol";

/// @title GovernanceUiHelper
/// @notice Utility contract to retrieve and format user’s staking and locking information,
///         including APR, for front-end or off-chain access in the MAHA DAO ecosystem.
/// @dev This contract fetches data from the `OmnichainStakingToken` contract, including reward rates,
///      total supply, and calculates APR based on locked balances and reward rates.
contract GovernanceUiHelper {
  /// @notice The staking contract associated with MAHA DAO governance for retrieving user’s locked balances
  OmnichainStakingToken public omnichainStaking;

  struct LockedBalanceWithApr {
    uint256 id;
    uint256 amount;
    uint256 end;
    uint256 start;
    uint256 power;
    uint256 apr;
  }

  /// @notice Constructor initializes the MahaUIHelper with the address of the OmnichainStakingToken contract.
  /// @param _omnichainStakingToken The address of the OmnichainStakingToken contract.
  constructor(
    address _omnichainStakingToken
  ) {
    omnichainStaking = OmnichainStakingToken(_omnichainStakingToken);
  }

  /// @notice Retrieves the details of all locked balances for a specified user.
  /// @dev Returns an array of `LockedBalanceWithApr` structs with details including lock amount,
  ///      APR calculation based on staking rewards, and lock duration.
  /// @param _userAddress The address of the user whose locked balances are retrieved.
  /// @return lockDetails Array of `LockedBalanceWithApr` structs containing lock ID, amount, start and end dates,
  ///         vePower, and scaled APR.
  function getLockDetails(
    address _userAddress
  ) external view returns (LockedBalanceWithApr[] memory) {
    (uint256[] memory tokenIds, ILocker.LockedBalance[] memory lockedBalances) =
      omnichainStaking.getLockedNftDetails(_userAddress);

    uint256 rewardRate1 = omnichainStaking.rewardRate(omnichainStaking.rewardToken1());
    uint256 rewardRate2 = omnichainStaking.rewardRate(omnichainStaking.rewardToken2());

    uint256 totalSupply = omnichainStaking.totalSupply();
    uint256 totalTokenIds = tokenIds.length;
    LockedBalanceWithApr[] memory lockDetails = new LockedBalanceWithApr[](totalTokenIds);

    for (uint256 i; i < totalTokenIds;) {
      LockedBalanceWithApr memory lock;
      ILocker.LockedBalance memory lockedBalance = lockedBalances[i];

      uint256 scale = (lockedBalance.power != 0 && lockedBalance.amount != 0)
        ? (lockedBalance.power * 1e18) / lockedBalance.amount
        : 1e18;

      uint256 poolRewardAnnual = (rewardRate1 + rewardRate2) * 31_536_000;
      uint256 apr = (poolRewardAnnual * 1000) / totalSupply;
      uint256 aprScaled = (apr * scale) / 1000;

      lock.id = tokenIds[i];
      lock.amount = lockedBalance.amount;
      lock.start = lockedBalance.start;
      lock.end = lockedBalance.end;
      lock.power = lockedBalance.power;
      lock.apr = aprScaled;

      lockDetails[i] = lock;

      unchecked {
        ++i;
      }
    }

    return lockDetails;
  }
}
