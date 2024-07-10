// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/ITokenLocker.sol";
import "../dependencies/PrismaOwnable.sol";
import "../dependencies/SystemStart.sol";

/**
    @title Prisma Boost Calculator
    @notice "Boost" refers to a bonus to claimable PRISMA tokens that an account
            receives based on it's locked PRISMA weight. An account with "max boost"
            is earning PRISMA rewards at a multiplier `maxBoostMultiplier` compared
            to the rate of an account that is unboosted.

            There are three phases of boost:

            1. The "max boost" phase, where claimed rewards are given at the maximum
            possible multiplier.
            2. The "decay" phase, where claimed rewards receive a linearly decaying
            boost multiplier.
            3. The "no boost" phase, where claimed rewards receive no multiplier.

            The amounts an account can claim with max and decaying boost are based
            on the percentage of lock weight that the account has, relative to the
            total lock weight. This percent is multiplied by `maxBoostablePct` or
            `decayBoostPct` to determine the final amount.

            At the start of each epoch, boost amounts are reset and the claim limits are
            recalculated according to the lock weight at the end of the previous epoch.

            As an example:

            * At the end of epoch 1, Alice has a lock weight of 100. There is a total
              lock weight of 1,000. Alice controls 10% of the total lock weight.
            * During epoch 2, a total of 500,000 new PRISMA rewards are made available.
            * `maxBoostablePct` is set to 200. This means that during epoch 2, Alice
              can claim up to 20% (10% * 200%) of the rewards (100,000 PRISMA) with the
              maximum boost multiplier.
            * Once Alice's claims exceed 100,000 PRISMA, she enters the decay phase.
              `decayBoostPct` is set to 50, meaning Alice can claim up to 5% (10% * 50%) of
              the rewards (25,000 PRISMA) with a decaying boost.
            * Once Alice's claims exceed 125,000 PRISMA, any further claims that epoch
              receive no boost.
            * At the start of the next epoch, Alice's boost is fully replenished. She still
              controls 10% of the total lock weight, so she can claim another 20% of this
              epoch's emissions at full boost.

            Note that boost is applied at the time of claiming a reward, not at the time
            the reward was earned. An account that has depleted it's boost may opt to wait
            for the start of the next epoch in order to claim with a larger boost.

            On a technical level, we consider the full earned reward to be the maximum
            boosted amount. "Unboosted" is more accurately described as "receiving a reduced
            reward amount". Rewards that are undistributed due to claims with lowered boost
            are returned to the unallocated token supply, and distributed again in the
            emissions of future epochs.
 */
contract BoostCalculator is PrismaOwnable, SystemStart {
    ITokenLocker public immutable locker;

    // initial number of epochs where all accounts recieve max boost
    uint256 public immutable MAX_BOOST_GRACE_EPOCHS;

    // epoch -> total epoch lock weight
    // tracked locally to avoid repeated external calls
    uint40[65535] totalEpochWeights;
    // account -> epoch -> % of lock weight (where 1e9 represents 100%)
    mapping(address account => uint32[65535]) accountEpochLockPct;

    // max boost multiplier as a whole number
    uint8 public maxBoostMultiplier;

    // percentage of the total epoch emissions that an account can claim with max
    // boost, expressed as a percent relative to the account's percent of the total
    // lock weight. For example, if an account has 5% of the lock weight and the
    // max boostable percent is 150, the account can claim 7.5% (5% * 150%) of the
    // epoch's emissions at a max boost.
    uint16 public maxBoostablePct;
    // percentage of the total epoch emissions that an account can claim with
    // decaying boost. Works the same as `maxBoostablePct`.
    uint16 public decayBoostPct;

    // pending boost multiplier and percentages that take effect in the next epoch
    uint8 public pendingMaxBoostMultiplier;
    uint16 public pendingMaxBoostablePct;
    uint16 public pendingDecayBoostPct;
    uint16 public paramChangeEpoch;

    event BoostParamsSet(
        uint256 maxBoostMultiplier,
        uint256 maxBoostablePct,
        uint256 decayBoostPct,
        uint256 paramChangeEpoch
    );

    constructor(
        address _prismaCore,
        ITokenLocker _locker,
        uint256 _graceEpochs,
        uint8 _maxBoostMul,
        uint16 _maxBoostPct,
        uint16 _decayPct
    ) PrismaOwnable(_prismaCore) SystemStart(_prismaCore) {
        locker = _locker;
        MAX_BOOST_GRACE_EPOCHS = _graceEpochs + getWeek();

        maxBoostMultiplier = _maxBoostMul;
        maxBoostablePct = _maxBoostPct;
        decayBoostPct = _decayPct;

        emit BoostParamsSet(_maxBoostMul, _maxBoostPct, _decayPct, getWeek());
    }

    /**
        @notice Set boost parameters
        @dev New parameters take effect in the following epoch
        @param maxBoostMul Maximum boost multiplier
        @param maxBoostPct Percentage of the total epoch emissions that an account
                           can claim with max boost, as a percent relative to the
                           account's percent of the total lock weight.
        @param decayPct Percentage of the total epoch emissions that an account
                        can claim with decaying boost, as a percent relative to the
                         account's percent of the total lock weight.
     */
    function setBoostParams(uint8 maxBoostMul, uint16 maxBoostPct, uint16 decayPct) external onlyOwner returns (bool) {
        require(maxBoostMul > 0, "Invalid maxBoostMul");
        pendingMaxBoostMultiplier = maxBoostMul;
        pendingMaxBoostablePct = maxBoostPct;
        pendingDecayBoostPct = decayPct;
        paramChangeEpoch = uint16(getWeek());

        emit BoostParamsSet(maxBoostMul, maxBoostPct, decayPct, getWeek());
        return true;
    }

    /**
        @notice Get the remaining claimable amounts this epoch that will receive boost
        @param account address to query boost amounts for
        @param previousAmount Amount that was already claimed in the current epoch
        @param totalEpochEmissions Total PRISMA emissions released this epoch
        @return maxBoosted remaining claimable amount that will receive max boost
        @return boosted remaining claimable amount that will receive some amount of boost (including max boost)
     */
    function getClaimableWithBoost(
        address account,
        uint256 previousAmount,
        uint256 totalEpochEmissions
    ) external view returns (uint256 maxBoosted, uint256 boosted) {
        uint256 epoch = getWeek();
        if (epoch < MAX_BOOST_GRACE_EPOCHS) {
            uint256 remaining = totalEpochEmissions - previousAmount;
            return (remaining, remaining);
        }
        epoch -= 1;

        uint256 accountWeight = locker.getAccountWeightAt(account, epoch);
        uint256 totalWeight = locker.getTotalWeightAt(epoch);
        if (totalWeight == 0) totalWeight = 1;
        uint256 pct = (1e9 * accountWeight) / totalWeight;
        if (pct == 0) return (0, 0);

        uint256 maxBoostMul;
        uint256 maxBoostable;
        uint256 fullDecay;
        if (paramChangeEpoch != 0 && paramChangeEpoch <= epoch) {
            maxBoostMul = pendingMaxBoostMultiplier;
            (maxBoostable, fullDecay) = _getBoostable(
                totalEpochEmissions,
                pct,
                pendingMaxBoostablePct,
                pendingDecayBoostPct
            );
        } else {
            maxBoostMul = maxBoostMultiplier;
            (maxBoostable, fullDecay) = _getBoostable(totalEpochEmissions, pct, maxBoostablePct, decayBoostPct);
        }

        return (
            previousAmount >= maxBoostable ? 0 : maxBoostable - previousAmount,
            previousAmount >= fullDecay ? 0 : fullDecay - previousAmount
        );
    }

    /**
        @notice Get the adjusted claim amount after applying an account's boost
        @param account Address claiming the reward
        @param amount Amount being claimed (assuming maximum boost)
        @param previousAmount Amount that was already claimed this epoch
        @param totalEpochEmissions Total PRISMA emissions released this epoch
        @return adjustedAmount Amount of PRISMA received after applying boost
     */
    function getBoostedAmount(
        address account,
        uint256 amount,
        uint256 previousAmount,
        uint256 totalEpochEmissions
    ) external view returns (uint256 adjustedAmount) {
        uint256 epoch = getWeek();
        if (epoch < MAX_BOOST_GRACE_EPOCHS) return amount;
        epoch -= 1;

        uint256 accountWeight = locker.getAccountWeightAt(account, epoch);
        uint256 totalWeight = locker.getTotalWeightAt(epoch);
        if (totalWeight == 0) totalWeight = 1;
        uint256 pct = (1e9 * accountWeight) / totalWeight;
        if (pct == 0) pct = 1;

        uint256 maxBoostMul;
        uint256 maxBoostable;
        uint256 fullDecay;
        if (paramChangeEpoch != 0 && paramChangeEpoch <= epoch) {
            maxBoostMul = pendingMaxBoostMultiplier;
            (maxBoostable, fullDecay) = _getBoostable(
                totalEpochEmissions,
                pct,
                pendingMaxBoostablePct,
                pendingDecayBoostPct
            );
        } else {
            maxBoostMul = maxBoostMultiplier;
            (maxBoostable, fullDecay) = _getBoostable(totalEpochEmissions, pct, maxBoostablePct, decayBoostPct);
        }

        return _getBoostedAmount(amount, previousAmount, pct, maxBoostMul, maxBoostable, fullDecay);
    }

    /**
        @notice Get the adjusted claim amount after applying an account's boost
        @dev Stores lock weights and percents to reduce cost on future calls
        @param account Address claiming the reward
        @param amount Amount being claimed (assuming maximum boost)
        @param previousAmount Amount that was already claimed this epoch
        @param totalEpochEmissions Total PRISMA emissions released this epoch
        @return adjustedAmount Amount of PRISMA received after applying boost
     */
    function getBoostedAmountWrite(
        address account,
        uint256 amount,
        uint256 previousAmount,
        uint256 totalEpochEmissions
    ) external returns (uint256 adjustedAmount) {
        uint256 epoch = getWeek();
        if (epoch < MAX_BOOST_GRACE_EPOCHS) return amount;
        epoch -= 1;

        // check for and apply new boost parameters
        uint256 pending = paramChangeEpoch;
        if (pending != 0 && pending <= epoch) {
            maxBoostMultiplier = pendingMaxBoostMultiplier;
            maxBoostablePct = pendingMaxBoostablePct;
            decayBoostPct = pendingDecayBoostPct;
            pendingMaxBoostMultiplier = 0;
            pendingMaxBoostablePct = 0;
            pendingDecayBoostPct = 0;
            paramChangeEpoch = 0;
        }

        uint256 lockPct = accountEpochLockPct[account][epoch];
        if (lockPct == 0) {
            uint256 totalWeight = totalEpochWeights[epoch];
            if (totalWeight == 0) {
                totalWeight = locker.getTotalWeightAt(epoch);
                if (totalWeight == 0) totalWeight = 1;
                totalEpochWeights[epoch] = uint40(totalWeight);
            }

            uint256 accountWeight = locker.getAccountWeightAt(account, epoch);
            lockPct = (1e9 * accountWeight) / totalWeight;
            if (lockPct == 0) lockPct = 1;
            accountEpochLockPct[account][epoch] = uint32(lockPct);
        }

        (uint256 maxBoostable, uint256 fullDecay) = _getBoostable(
            totalEpochEmissions,
            lockPct,
            maxBoostablePct,
            decayBoostPct
        );

        return _getBoostedAmount(amount, previousAmount, lockPct, maxBoostMultiplier, maxBoostable, fullDecay);
    }

    function _getBoostable(
        uint256 totalEpochEmissions,
        uint256 lockPct,
        uint256 maxBoostPct,
        uint256 decayPct
    ) internal pure returns (uint256, uint256) {
        uint256 maxBoostable = (totalEpochEmissions * lockPct * maxBoostPct) / 1e11;
        uint256 fullDecay = maxBoostable + (totalEpochEmissions * lockPct * decayPct) / 1e11;
        return (maxBoostable, fullDecay);
    }

    function _getBoostedAmount(
        uint256 amount,
        uint256 previousAmount,
        uint256 lockPct,
        uint256 maxBoostMul,
        uint256 maxBoostable,
        uint256 fullDecay
    ) internal pure returns (uint256 adjustedAmount) {
        // we use 1 to indicate no lock weight: no boost
        if (lockPct == 1) return amount / maxBoostMul;

        uint256 total = amount + previousAmount;

        // entire claim receives max boost
        if (maxBoostable >= total) return amount;

        // entire claim receives no boost
        if (fullDecay <= previousAmount) return amount / maxBoostMul;

        // apply max boost for partial claim
        if (previousAmount < maxBoostable) {
            adjustedAmount = maxBoostable - previousAmount;
            amount -= adjustedAmount;
            previousAmount = maxBoostable;
        }

        // apply no boost for partial claim
        if (total > fullDecay) {
            adjustedAmount += (total - fullDecay) / maxBoostMul;
            amount -= (total - fullDecay);
            total = amount + previousAmount;
        }

        // simplified calculation if remaining claim is the entire decay amount
        uint256 decay = fullDecay - maxBoostable;
        if (amount == decay) return adjustedAmount + ((decay / maxBoostMul) * (maxBoostMul + 1)) / 2;

        /**
            calculate adjusted amount when the claim spans only part of the decay. we can
            visualize the decay calculation as a right angle triangle:

             * the X axis runs from 0 to `(fullDecay - maxBoostable) / MAX_BOOST_MULTIPLIER`
             * the Y axis runs from 1 to `MAX_BOOST_MULTIPLER`

            we slice the triangle at two points along the x axis, based on the previously claimed
            amount and the new amount to claim. we then divide this new shape into another right
            angle triangle and a rectangle, calculate and sum the areas. the sum is the final
            adjusted amount.
         */

        // x axis calculations (+1e9 precision multiplier)
        // length of the original triangle
        uint unboostedTotal = (decay * 1e9) / maxBoostMul;
        // point for first slice
        uint claimStart = ((previousAmount - maxBoostable) * 1e9) / maxBoostMul;
        // point for second slice
        uint claimEnd = ((total - maxBoostable) * 1e9) / maxBoostMul;
        // length of the slice
        uint claimDelta = claimEnd - claimStart;

        // y axis calculations (+1e9 precision multiplier)
        uint ymul = 1e9 * (maxBoostMul - 1);
        // boost at the first slice
        uint boostStart = (ymul * (unboostedTotal - claimStart)) / unboostedTotal + 1e9;
        // boost at the 2nd slice
        uint boostEnd = (ymul * (unboostedTotal - claimEnd)) / unboostedTotal + 1e9;

        // area calculations
        // area of the new right angle triangle within our slice of the old triangle
        uint decayAmount = (claimDelta * (boostStart - boostEnd)) / 2;
        // area of the rectangular section within our slice of the old triangle
        uint fullAmount = claimDelta * boostEnd;

        // sum areas and remove precision multipliers
        adjustedAmount += (decayAmount + fullAmount) / 1e18;

        return adjustedAmount;
    }
}
