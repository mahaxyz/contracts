// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

import {VestedZeroNFT} from "../vesting/VestedZeroNFT.sol";
import {OmnichainStakingToken} from "../locker/staking/OmnichainStakingToken.sol";
import {OmnichainStakingLP} from "../locker/staking/OmnichainStakingLP.sol";
import {ILocker} from "../interfaces/ILocker.sol";

/// @title VestedZeroNFT is a NFT based contract to hold all the user vests
contract VestUiHelper {
    VestedZeroNFT public vestedZero;
    OmnichainStakingToken public omnichainStaking;
    OmnichainStakingLP public omnichainStakingLp;

    struct VestDetails {
        uint256 id;
        uint256 cliffDuration;
        uint256 unlockDate;
        uint256 pendingClaimed;
        uint256 pending;
        uint256 upfrontClaimed;
        uint256 upfront;
        uint256 linearDuration;
        uint256 createdAt;
        bool hasPenalty;
        VestedZeroNFT.VestCategory category;
        uint256 claimable;
        uint256 unClaimed;
        uint256 penalty;
        bool isFrozen;
    }

    struct LockedBalanceWithApr {
        uint256 id;
        uint256 amount;
        uint256 end;
        uint256 start;
        uint256 power;
        uint256 apr;
    }

    constructor(
        address _vestedZeroNFT,
        address _omnichainStaking,
        address _omnichainStakingLp
    ) {
        vestedZero = VestedZeroNFT(_vestedZeroNFT);
        omnichainStaking = OmnichainStakingToken(_omnichainStaking);
        omnichainStakingLp = OmnichainStakingLP(payable(_omnichainStakingLp));
    }

    function getVestedNFTData(
        address _userAddress
    ) external view returns (VestDetails[] memory) {
        uint256 nftsOwned = vestedZero.balanceOf(_userAddress);
        VestDetails[] memory lockDetails = new VestDetails[](nftsOwned);
        for (uint i; i < nftsOwned; ) {
            VestDetails memory lock;
            uint256 tokenId = vestedZero.tokenOfOwnerByIndex(_userAddress, i);
            (
                lock.cliffDuration,
                lock.unlockDate,
                lock.pendingClaimed,
                lock.pending,
                lock.upfrontClaimed,
                ,
                ,
                ,
                ,

            ) = vestedZero.tokenIdToLockDetails(tokenId);
            (
                ,
                ,
                ,
                ,
                ,
                lock.upfront,
                lock.linearDuration,
                lock.createdAt,
                lock.hasPenalty,
                lock.category
            ) = vestedZero.tokenIdToLockDetails(tokenId);

            (uint256 upfrontClaimable, uint256 pendingClaimable) = vestedZero
                .claimable(tokenId);

            lock.id = tokenId;
            lock.penalty = vestedZero.penalty(tokenId);
            lock.claimable =
                upfrontClaimable +
                pendingClaimable -
                (lock.upfrontClaimed + lock.pendingClaimed);
            lock.unClaimed = vestedZero.unclaimed(tokenId);
            lock.isFrozen = vestedZero.frozen(tokenId);

            lockDetails[i] = lock;

            unchecked {
                ++i;
            }
        }

        return lockDetails;
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
