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

pragma solidity 0.8.19;

library ZAIEventsLib {
    event BorrowingFeePaid(address indexed borrower, uint256 amount);
    event CollateralConfigured(address troveManager, address collateralToken);
    event TroveCreated(address indexed _borrower, uint256 arrayIndex);
    event TroveManagerRemoved(address troveManager);
    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 stake,
        uint8 operation
    );
    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 _stake,
        TroveManagerOperation _operation
    );
    event Redemption(
        uint256 _attemptedDebtAmount,
        uint256 _actualDebtAmount,
        uint256 _collateralSent,
        uint256 _collateralFee
    );
    event BaseRateUpdated(uint256 _baseRate);
    event LastFeeOpTimeUpdated(uint256 _lastFeeOpTime);
    event TotalStakesUpdated(uint256 _newTotalStakes);
    event SystemSnapshotsUpdated(
        uint256 _totalStakesSnapshot,
        uint256 _totalCollateralSnapshot
    );
    event LTermsUpdated(uint256 _L_collateral, uint256 _L_debt);
    event TroveSnapshotsUpdated(uint256 _L_collateral, uint256 _L_debt);
    event TroveIndexUpdated(address _borrower, uint256 _newIndex);
    event CollateralSent(address _to, uint256 _amount);
    event RewardClaimed(
        address indexed account,
        address indexed recipient,
        uint256 claimed
    );

    event StabilityPoolDebtBalanceUpdated(uint256 _newBalance);

    event P_Updated(uint256 _P);
    event S_Updated(uint256 idx, uint256 _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event DepositSnapshotUpdated(
        address indexed _depositor,
        uint256 _P,
        uint256 _G
    );
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);

    event CollateralGainWithdrawn(
        address indexed _depositor,
        uint256[] _collateral
    );
    event CollateralOverwritten(IERC20 oldCollateral, IERC20 newCollateral);

    event RewardClaimed(
        address indexed account,
        address indexed recipient,
        uint256 claimed
    );

    event NewOwnerAccepted(address oldOwner, address owner);

    event NewOwnerRevoked(address owner, address revokedOwner);

    event FeeReceiverSet(address feeReceiver);

    event PriceFeedSet(address priceFeed);

    event GuardianSet(address guardian);

    event Paused();

    event Unpaused();

    event NewDeployment(
        address collateral,
        address priceFeed,
        address troveManager,
        address sortedTroves
    );
}
