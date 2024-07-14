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

import {OmnichainStakingToken} from "../../governance/locker/staking/OmnichainStakingToken.sol";
import {OmnichainStakingLP} from "../../governance/locker/staking/OmnichainStakingLP.sol";
import {ILocker} from "../../interfaces/governance/ILocker.sol";

contract VestUiHelper {
    OmnichainStakingToken public omnichainStaking;
    OmnichainStakingLP public omnichainStakingLp;

    struct LockedBalanceWithApr {
        uint256 id;
        uint256 amount;
        uint256 end;
        uint256 start;
        uint256 power;
        uint256 apr;
    }

    constructor(address _omnichainStaking, address _omnichainStakingLp) {
        omnichainStaking = OmnichainStakingToken(_omnichainStaking);
        omnichainStakingLp = OmnichainStakingLP(payable(_omnichainStakingLp));
    }

    function getLockDetails(
        address _userAddress
    ) external view returns (LockedBalanceWithApr[] memory) {
        (
            uint256[] memory tokenIds,
            ILocker.LockedBalance[] memory lockedBalances
        ) = omnichainStaking.getLockedNftDetails(_userAddress);

        uint256 rewardRate = omnichainStaking.rewardRate();
        uint256 totalSupply = omnichainStaking.totalSupply();

        uint256 totalTokenIds = tokenIds.length;
        LockedBalanceWithApr[] memory lockDetails = new LockedBalanceWithApr[](
            totalTokenIds
        );

        for (uint i; i < totalTokenIds; ) {
            LockedBalanceWithApr memory lock;
            ILocker.LockedBalance memory lockedBalance = lockedBalances[i];

            uint256 vePower = omnichainStaking.getTokenPower(
                lockedBalance.amount
            );

            uint256 scale = (lockedBalance.power != 0 &&
                lockedBalance.amount != 0)
                ? (lockedBalance.power * 1e18) / lockedBalance.amount
                : 1e18;

            uint256 poolRewardAnnual = rewardRate * 31536000;
            uint256 apr = (poolRewardAnnual * 1000) / totalSupply;
            uint256 aprScaled = (apr * scale) / 1000;

            lock.id = tokenIds[i];
            lock.amount = lockedBalance.amount;
            lock.start = lockedBalance.start;
            lock.end = lockedBalance.end;
            lock.power = vePower;
            lock.apr = aprScaled;

            lockDetails[i] = lock;

            unchecked {
                ++i;
            }
        }

        return lockDetails;
    }

    function getLPLockDetails(
        address _userAddress
    ) external view returns (LockedBalanceWithApr[] memory) {
        (
            uint256[] memory tokenIds,
            ILocker.LockedBalance[] memory lockedBalances
        ) = omnichainStakingLp.getLockedNftDetails(_userAddress);

        uint256 rewardRate = omnichainStakingLp.rewardRate();
        uint256 totalSupply = omnichainStakingLp.totalSupply();

        uint256 totalTokenIds = tokenIds.length;
        LockedBalanceWithApr[] memory lockDetails = new LockedBalanceWithApr[](
            totalTokenIds
        );

        for (uint i; i < totalTokenIds; ) {
            LockedBalanceWithApr memory lock;
            ILocker.LockedBalance memory lockedBalance = lockedBalances[i];

            uint256 vePower = omnichainStakingLp.getTokenPower(
                lockedBalance.amount
            );

            uint256 scale = (lockedBalance.power != 0 &&
                lockedBalance.amount != 0)
                ? (lockedBalance.power * 1e18) / lockedBalance.amount
                : 1e18;

            uint256 priceConversion = zeroToETH();

            uint256 poolRewardAnnual = rewardRate * 31536000;
            uint256 apr = (priceConversion * (poolRewardAnnual * 1000)) /
                totalSupply;
            uint256 aprScaled = (apr * scale) / 1000;

            lock.id = tokenIds[i];
            lock.amount = lockedBalance.amount;
            lock.start = lockedBalance.start;
            lock.end = lockedBalance.end;
            lock.power = vePower;
            lock.apr = aprScaled;

            lockDetails[i] = lock;

            unchecked {
                ++i;
            }
        }

        return lockDetails;
    }

    function zeroToETH() public pure returns (uint256) {
        return 6753941;
    }
}
