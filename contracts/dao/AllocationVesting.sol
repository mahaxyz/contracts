// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DelegatedOps } from "../dependencies/DelegatedOps.sol";
import { ITokenLocker } from "../interfaces/ITokenLocker.sol";

/**
 * @title Vesting contract for team and investors
 * @author PrismaFi
 * @notice Vesting contract which allows transfer of future vesting claims
 */
contract AllocationVesting is DelegatedOps {
    error NothingToClaim();
    error CannotLock();
    error WrongMaxTotalPreclaimPct();
    error PreclaimTooLarge();
    error AllocationsMismatch();
    error ZeroTotalAllocation();
    error ZeroAllocation();
    error ZeroNumberOfWeeks();
    error DuplicateAllocation();
    error InsufficientPoints();
    error LockedAllocation();
    error SelfTransfer();
    error IncompatibleVestingPeriod(uint256 numberOfWeeksFrom, uint256 numberOfWeeksTo);

    struct AllocationSplit {
        address recipient;
        uint24 points;
        uint8 numberOfWeeks;
    }

    struct AllocationState {
        uint24 points;
        uint8 numberOfWeeks;
        uint128 claimed;
        uint96 preclaimed;
    }

    // This number should allow a good precision in allocation fractions
    uint256 private immutable totalPoints;
    // Users allocations
    mapping(address => AllocationState) public allocations;
    // max percentage of one's vest that can be preclaimed in total
    uint256 public immutable maxTotalPreclaimPct;
    // Total allocation expressed in tokens
    uint256 public immutable totalAllocation;
    IERC20 public immutable vestingToken;
    address public immutable vault;
    ITokenLocker public immutable tokenLocker;
    uint256 public immutable lockToTokenRatio;
    // Vesting timeline starting timestamp
    uint256 public immutable vestingStart;

    constructor(
        IERC20 vestingToken_,
        ITokenLocker tokenLocker_,
        uint256 totalAllocation_,
        address vault_,
        uint256 maxTotalPreclaimPct_,
        uint256 vestingStart_,
        AllocationSplit[] memory allocationSplits
    ) {
        if (totalAllocation_ == 0) revert ZeroTotalAllocation();
        if (maxTotalPreclaimPct_ > 20) revert WrongMaxTotalPreclaimPct();
        vault = vault_;
        tokenLocker = tokenLocker_;
        vestingToken = vestingToken_;
        totalAllocation = totalAllocation_;
        lockToTokenRatio = tokenLocker_.lockToTokenRatio();
        maxTotalPreclaimPct = maxTotalPreclaimPct_;

        vestingStart = vestingStart_;
        uint256 loopEnd = allocationSplits.length;
        uint256 total;
        for (uint256 i; i < loopEnd; ) {
            address recipient = allocationSplits[i].recipient;
            uint8 numberOfWeeks = allocationSplits[i].numberOfWeeks;
            uint256 points = allocationSplits[i].points;
            if (points == 0) revert ZeroAllocation();
            if (numberOfWeeks == 0) revert ZeroNumberOfWeeks();
            if (allocations[recipient].numberOfWeeks > 0) revert DuplicateAllocation();
            total += points;
            allocations[recipient].points = uint24(points);
            allocations[recipient].numberOfWeeks = numberOfWeeks;
            unchecked {
                ++i;
            }
        }
        totalPoints = total;
    }

    /**
     * @notice Claims accrued tokens for initiator and transfers a number of allocation points to a recipient
     * @dev Can be delegated
     * @param from Initiator
     * @param to Recipient
     * @param points Number of points to transfer
     */
    function transferPoints(address from, address to, uint256 points) external callerOrDelegated(from) {
        if (from == to) revert SelfTransfer();
        AllocationState memory fromAllocation = allocations[from];
        AllocationState memory toAllocation = allocations[to];
        uint8 numberOfWeeksFrom = fromAllocation.numberOfWeeks;
        uint8 numberOfWeeksTo = toAllocation.numberOfWeeks;
        uint256 pointsFrom = fromAllocation.points;
        if (numberOfWeeksTo != 0 && numberOfWeeksTo != numberOfWeeksFrom)
            revert IncompatibleVestingPeriod(numberOfWeeksFrom, numberOfWeeksTo);
        uint256 totalVested = _vestedAt(block.timestamp, pointsFrom, numberOfWeeksFrom);
        if (totalVested < fromAllocation.claimed) revert LockedAllocation();
        if (points == 0) revert ZeroAllocation();
        if (pointsFrom < points) revert InsufficientPoints();
        // We claim one last time before transfer
        uint256 claimed = _claim(from, pointsFrom, fromAllocation.claimed, numberOfWeeksFrom);
        // Passive balance to transfer
        uint128 claimedAdjustment = uint128((claimed * points) / fromAllocation.points);
        allocations[from].points = uint24(pointsFrom - points);
        // we can't use fromAllocation.claimed since the storage value was modified by the _claim() call
        allocations[from].claimed = allocations[from].claimed - claimedAdjustment;
        allocations[to].points = toAllocation.points + uint24(points);
        allocations[to].claimed = toAllocation.claimed + claimedAdjustment;
        // Transfer preclaimed pro-rata to avoid limit gaming
        uint256 preclaimedToTransfer = (fromAllocation.preclaimed * points) / pointsFrom;
        allocations[to].preclaimed = uint96(toAllocation.preclaimed + preclaimedToTransfer);
        allocations[from].preclaimed = uint96(fromAllocation.preclaimed - preclaimedToTransfer);
        if (numberOfWeeksTo == 0) {
            allocations[to].numberOfWeeks = numberOfWeeksFrom;
        }
    }

    /**
     * @notice Lock future claimable tokens tokens
     * @dev Can be delegated
     * @param account Account to lock for
     * @param amount Amount to preclaim
     */
    function lockFutureClaims(address account, uint256 amount) external callerOrDelegated(account) {
        lockFutureClaimsWithReceiver(account, account, amount);
    }

    /**
     * @notice Lock future claimable tokens tokens
     * @dev Can be delegated
     * @param account Account to lock for
     * @param receiver Receiver of the lock
     * @param amount Amount to preclaim. If 0 the maximum allowed will be locked
     */
    function lockFutureClaimsWithReceiver(
        address account,
        address receiver,
        uint256 amount
    ) public callerOrDelegated(account) {
        AllocationState memory allocation = allocations[account];
        if (allocation.points == 0 || vestingStart == 0) revert CannotLock();
        uint256 claimedUpdated = allocation.claimed;
        if (_claimableAt(block.timestamp, allocation.points, allocation.claimed, allocation.numberOfWeeks) > 0) {
            claimedUpdated = _claim(account, allocation.points, allocation.claimed, allocation.numberOfWeeks);
        }
        uint256 userAllocation = (allocation.points * totalAllocation) / totalPoints;
        uint256 _unclaimed = userAllocation - claimedUpdated;
        uint256 preclaimed = allocation.preclaimed;
        uint256 maxTotalPreclaim = (maxTotalPreclaimPct * userAllocation) / 100;
        uint256 leftToPreclaim = maxTotalPreclaim - preclaimed;
        if (amount == 0) amount = leftToPreclaim > _unclaimed ? _unclaimed : leftToPreclaim;
        else if (preclaimed + amount > maxTotalPreclaim || amount > _unclaimed) revert PreclaimTooLarge();
        amount = (amount / lockToTokenRatio) * lockToTokenRatio; // truncating the dust
        allocations[account].claimed = uint128(claimedUpdated + amount);
        allocations[account].preclaimed = uint96(preclaimed + amount);
        vestingToken.transferFrom(vault, address(this), amount);
        tokenLocker.lock(receiver, amount / lockToTokenRatio, 52);
    }

    /**
     *
     * @notice Claims accrued tokens
     * @dev Can be delegated
     * @param account Account to claim for
     */
    function claim(address account) external callerOrDelegated(account) {
        AllocationState memory allocation = allocations[account];
        _claim(account, allocation.points, allocation.claimed, allocation.numberOfWeeks);
    }

    // This function exists to avoid reloading the AllocationState struct in memory
    function _claim(
        address account,
        uint256 points,
        uint256 claimed,
        uint256 numberOfWeeks
    ) private returns (uint256 claimedUpdated) {
        if (points == 0) revert NothingToClaim();
        uint256 claimable = _claimableAt(block.timestamp, points, claimed, numberOfWeeks);
        if (claimable == 0) revert NothingToClaim();
        claimedUpdated = claimed + claimable;
        allocations[account].claimed = uint128(claimedUpdated);
        // We send to delegate for possible zaps
        vestingToken.transferFrom(vault, msg.sender, claimable);
    }

    /**
     * @notice Calculates number of tokens claimable by the user at the current block
     * @param account Account to calculate for
     * @return claimable Accrued tokens
     */
    function claimableNow(address account) external view returns (uint256 claimable) {
        AllocationState memory allocation = allocations[account];
        claimable = _claimableAt(block.timestamp, allocation.points, allocation.claimed, allocation.numberOfWeeks);
    }

    function _claimableAt(
        uint256 when,
        uint256 points,
        uint256 claimed,
        uint256 numberOfWeeks
    ) private view returns (uint256) {
        uint256 totalVested = _vestedAt(when, points, numberOfWeeks);
        return totalVested > claimed ? totalVested - claimed : 0;
    }

    function _vestedAt(uint256 when, uint256 points, uint256 numberOfWeeks) private view returns (uint256 vested) {
        if (vestingStart == 0 || numberOfWeeks == 0) return 0;
        uint256 vestingWeeks = numberOfWeeks * 1 weeks;
        uint256 vestingEnd = vestingStart + vestingWeeks;
        uint256 endTime = when >= vestingEnd ? vestingEnd : when;
        uint256 timeSinceStart = endTime - vestingStart;
        vested = (totalAllocation * timeSinceStart * points) / (totalPoints * vestingWeeks);
    }

    /**
     * @notice Calculates the total number of tokens left unclaimed by the user including unvested ones
     * @param account Account to calculate for
     * @return Unclaimed tokens
     */
    function unclaimed(address account) external view returns (uint256) {
        AllocationState memory allocation = allocations[account];
        uint256 accountAllocation = (totalAllocation * allocation.points) / totalPoints;
        return accountAllocation - allocation.claimed;
    }

    /**
     * @notice Calculates the total number of tokens left to preclaim
     * @param account Account to calculate for
     * @return Preclaimable tokens
     */
    function preclaimable(address account) external view returns (uint256) {
        AllocationState memory allocation = allocations[account];
        if (allocation.points == 0 || vestingStart == 0) return 0;
        uint256 userAllocation = (allocation.points * totalAllocation) / totalPoints;
        uint256 preclaimed = allocation.preclaimed;
        uint256 maxTotalPreclaim = (maxTotalPreclaimPct * userAllocation) / 100;
        return maxTotalPreclaim - preclaimed;
    }
}
