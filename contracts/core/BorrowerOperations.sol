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

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITroveManager} from "../interfaces/ITroveManager.sol";
import {IBorrowerOperations} from "../interfaces/IBorrowerOperations.sol";
import {IZaiPermissioned} from "../interfaces/IZaiPermissioned.sol";
import {ZaiBase} from "./dependencies/ZaiBase.sol";
import {ZaiMath} from "./dependencies/ZaiMath.sol";
import {ZaiOwnable, IZaiOwnable} from "./dependencies/ZaiOwnable.sol";
import {DelegatedOps} from "./dependencies/DelegatedOps.sol";
import {ZAIEventsLib} from "../interfaces/events/ZAIEventsLib.sol";

/**
 * @title Zai Borrower Operations
 * @author maha.xyz
 * @notice Based on Liquity's `BorrowerOperations`
 * https://github.com/liquity/dev/blob/main/packages/contracts/contracts/BorrowerOperations.sol
 * Zai's implementation is modified to support multiple collaterals. There is a 1:n
 * relationship between `BorrowerOperations` and each `TroveManager` / `SortedTroves` pair.
 */
contract BorrowerOperations is
    IBorrowerOperations,
    ZaiBase,
    ZaiOwnable,
    DelegatedOps
{
    using SafeERC20 for IERC20;

    /// @inheritdoc IBorrowerOperations
    IZaiPermissioned public immutable debtToken;

    /// @inheritdoc IBorrowerOperations
    address public immutable factory;

    /// @inheritdoc IBorrowerOperations
    uint256 public minNetDebt;

    mapping(ITroveManager => TroveManagerData) internal _troveManagersData;
    ITroveManager[] internal _troveManagers;

    constructor(
        address _zaiCore,
        address _debtTokenAddress,
        address _factory,
        uint256 _minNetDebt,
        uint256 _gasCompensation
    ) ZaiOwnable(_zaiCore) ZaiBase(_gasCompensation) {
        debtToken = IZaiPermissioned(_debtTokenAddress);
        factory = _factory;
        _setMinNetDebt(_minNetDebt);
    }

    /// @inheritdoc IBorrowerOperations
    function setMinNetDebt(uint256 _minNetDebt) public onlyOwner {
        _setMinNetDebt(_minNetDebt);
    }

    /// @inheritdoc IBorrowerOperations
    function configureCollateral(
        ITroveManager troveManager,
        IERC20 collateralToken
    ) external {
        require(msg.sender == factory, "!factory");
        _troveManagersData[troveManager] = TroveManagerData(
            collateralToken,
            uint16(_troveManagers.length)
        );
        _troveManagers.push(troveManager);
        emit ZAIEventsLib.CollateralConfigured(
            address(troveManager),
            address(collateralToken)
        );
    }

    /// @inheritdoc IBorrowerOperations
    function removeTroveManager(ITroveManager troveManager) external {
        TroveManagerData memory tmData = _troveManagersData[troveManager];
        require(
            address(tmData.collateralToken) != address(0) &&
                troveManager.sunsetting() &&
                troveManager.getEntireSystemDebt() == 0,
            "Trove Manager cannot be removed"
        );
        delete _troveManagersData[troveManager];
        uint256 lastIndex = _troveManagers.length - 1;
        if (tmData.index < lastIndex) {
            ITroveManager lastTm = _troveManagers[lastIndex];
            _troveManagers[tmData.index] = lastTm;
            _troveManagersData[lastTm].index = tmData.index;
        }

        _troveManagers.pop();
        emit ZAIEventsLib.TroveManagerRemoved(address(troveManager));
    }

    /**
     * @notice Get the global total collateral ratio
     * @dev Not a view because fetching from the oracle is state changing.
     * Can still be accessed as a view from within the UX.
     */
    /// @inheritdoc IBorrowerOperations
    function getTCR() external returns (uint256 globalTotalCollateralRatio) {
        SystemBalances memory balances = fetchBalances();
        (globalTotalCollateralRatio, , ) = _getTCRData(balances);
        return globalTotalCollateralRatio;
    }

    /**
     * @notice Get total collateral and debt balances for all active collaterals, as well as
     * the current collateral prices
     * @dev Not a view because fetching from the oracle is state changing.
     * Can still be accessed as a view from within the UX.
     */
    /// @inheritdoc IBorrowerOperations
    function fetchBalances() public returns (SystemBalances memory balances) {
        uint256 loopEnd = _troveManagers.length;
        balances = SystemBalances({
            collaterals: new uint256[](loopEnd),
            debts: new uint256[](loopEnd),
            prices: new uint256[](loopEnd)
        });
        for (uint256 i; i < loopEnd; ) {
            ITroveManager troveManager = _troveManagers[i];
            (uint256 collateral, uint256 debt, uint256 price) = troveManager
                .getEntireSystemBalances();
            balances.collaterals[i] = collateral;
            balances.debts[i] = debt;
            balances.prices[i] = price;
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IBorrowerOperations
    function checkRecoveryMode(uint256 TCR) public pure returns (bool) {
        return TCR < CCR;
    }

    /// @inheritdoc IBorrowerOperations
    function getCompositeDebt(uint256 _debt) external view returns (uint256) {
        return _getCompositeDebt(_debt);
    }

    // --- Borrower Trove Operations ---
    /// @inheritdoc IBorrowerOperations
    function openTrove(
        ITroveManager troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _collateralAmount,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external callerOrDelegated(account) {
        require(!ZAI_CORE.paused(), "Deposits are paused");
        IERC20 collateralToken;
        LocalVariables_openTrove memory vars;
        bool isRecoveryMode;
        (
            collateralToken,
            vars.price,
            vars.totalPricedCollateral,
            vars.totalDebt,
            isRecoveryMode
        ) = _getCollateralAndTCRData(troveManager);

        _requireValidMaxFeePercentage(_maxFeePercentage);

        vars.netDebt = _debtAmount;

        if (!isRecoveryMode) {
            vars.netDebt =
                vars.netDebt +
                _triggerBorrowingFee(
                    troveManager,
                    collateralToken,
                    account,
                    _maxFeePercentage,
                    _debtAmount
                );
        }
        _requireAtLeastMinNetDebt(vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested Debt amount + Debt borrowing fee + Debt gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        vars.ICR = ZaiMath._computeCR(
            _collateralAmount,
            vars.compositeDebt,
            vars.price
        );
        vars.NICR = ZaiMath._computeNominalCR(
            _collateralAmount,
            vars.compositeDebt
        );

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR, troveManager.MCR());
            uint256 newTCR = _getNewTCRFromTroveChange(
                vars.totalPricedCollateral,
                vars.totalDebt,
                _collateralAmount * vars.price,
                true,
                vars.compositeDebt,
                true
            ); // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR);
        }

        // Create the trove
        (vars.stake, vars.arrayIndex) = troveManager.openTrove(
            account,
            _collateralAmount,
            vars.compositeDebt,
            vars.NICR,
            _upperHint,
            _lowerHint,
            isRecoveryMode
        );

        // Move the collateral to the Trove Manager
        collateralToken.safeTransferFrom(
            msg.sender,
            address(troveManager),
            _collateralAmount
        );

        //  and mint the DebtAmount to the caller and gas compensation for Gas Pool
        debtToken.mintWithGasCompensation(msg.sender, _debtAmount);
    }

    // Send collateral to a trove
    /// @inheritdoc IBorrowerOperations
    function addColl(
        ITroveManager troveManager,
        address account,
        uint256 _collateralAmount,
        address _upperHint,
        address _lowerHint
    ) external callerOrDelegated(account) {
        require(!ZAI_CORE.paused(), "Trove adjustments are paused");
        _adjustTrove(
            troveManager,
            account,
            0,
            _collateralAmount,
            0,
            0,
            false,
            _upperHint,
            _lowerHint
        );
    }

    // Withdraw collateral from a trove
    /// @inheritdoc IBorrowerOperations
    function withdrawColl(
        ITroveManager troveManager,
        address account,
        uint256 _collWithdrawal,
        address _upperHint,
        address _lowerHint
    ) external callerOrDelegated(account) {
        _adjustTrove(
            troveManager,
            account,
            0,
            0,
            _collWithdrawal,
            0,
            false,
            _upperHint,
            _lowerHint
        );
    }

    // Withdraw Debt tokens from a trove: mint new Debt tokens to the owner, and increase the trove's debt accordingly
    /// @inheritdoc IBorrowerOperations
    function withdrawDebt(
        ITroveManager troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external callerOrDelegated(account) {
        require(!ZAI_CORE.paused(), "Withdrawals are paused");
        _adjustTrove(
            troveManager,
            account,
            _maxFeePercentage,
            0,
            0,
            _debtAmount,
            true,
            _upperHint,
            _lowerHint
        );
    }

    // Repay Debt tokens to a Trove: Burn the repaid Debt tokens, and reduce the trove's debt accordingly
    /// @inheritdoc IBorrowerOperations
    function repayDebt(
        ITroveManager troveManager,
        address account,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external callerOrDelegated(account) {
        _adjustTrove(
            troveManager,
            account,
            0,
            0,
            0,
            _debtAmount,
            false,
            _upperHint,
            _lowerHint
        );
    }

    /// @inheritdoc IBorrowerOperations
    function adjustTrove(
        ITroveManager troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _collDeposit,
        uint256 _collWithdrawal,
        uint256 _debtChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external callerOrDelegated(account) {
        require(
            (_collDeposit == 0 && !_isDebtIncrease) || !ZAI_CORE.paused(),
            "Trove adjustments are paused"
        );
        require(
            _collDeposit == 0 || _collWithdrawal == 0,
            "BorrowerOperations: Cannot withdraw and add coll"
        );
        _adjustTrove(
            troveManager,
            account,
            _maxFeePercentage,
            _collDeposit,
            _collWithdrawal,
            _debtChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint
        );
    }

    function _adjustTrove(
        ITroveManager troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _collDeposit,
        uint256 _collWithdrawal,
        uint256 _debtChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) internal {
        require(
            _collDeposit != 0 || _collWithdrawal != 0 || _debtChange != 0,
            "BorrowerOps: There must be either a collateral change or a debt change"
        );

        IERC20 collateralToken;
        LocalVariables_adjustTrove memory vars;
        bool isRecoveryMode;
        (
            collateralToken,
            vars.price,
            vars.totalPricedCollateral,
            vars.totalDebt,
            isRecoveryMode
        ) = _getCollateralAndTCRData(troveManager);

        (vars.coll, vars.debt) = troveManager.applyPendingRewards(account);

        // Get the collChange based on whether or not collateral was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(
            _collDeposit,
            _collWithdrawal
        );
        vars.netDebtChange = _debtChange;
        vars.debtChange = _debtChange;
        vars.account = account;
        vars.MCR = troveManager.MCR();

        if (_isDebtIncrease) {
            require(
                _debtChange > 0,
                "BorrowerOps: Debt increase requires non-zero debtChange"
            );
            _requireValidMaxFeePercentage(_maxFeePercentage);
            if (!isRecoveryMode) {
                // If the adjustment incorporates a debt increase and system is in Normal Mode, trigger a borrowing fee
                vars.netDebtChange += _triggerBorrowingFee(
                    troveManager,
                    collateralToken,
                    msg.sender,
                    _maxFeePercentage,
                    _debtChange
                );
            }
        }

        // Calculate old and new ICRs and check if adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(
            vars.totalPricedCollateral,
            vars.totalDebt,
            isRecoveryMode,
            _collWithdrawal,
            _isDebtIncrease,
            vars
        );

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough Debt
        if (!_isDebtIncrease && _debtChange > 0) {
            _requireAtLeastMinNetDebt(
                _getNetDebt(vars.debt) - vars.netDebtChange
            );
        }

        // If we are incrasing collateral, send tokens to the trove manager prior to adjusting the trove
        if (vars.isCollIncrease)
            collateralToken.safeTransferFrom(
                msg.sender,
                address(troveManager),
                vars.collChange
            );

        (vars.newColl, vars.newDebt, vars.stake) = troveManager
            .updateTroveFromAdjustment(
                isRecoveryMode,
                _isDebtIncrease,
                vars.debtChange,
                vars.netDebtChange,
                vars.isCollIncrease,
                vars.collChange,
                _upperHint,
                _lowerHint,
                vars.account,
                msg.sender
            );
    }

    /// @inheritdoc IBorrowerOperations
    function closeTrove(
        ITroveManager troveManager,
        address account
    ) external callerOrDelegated(account) {
        IERC20 collateralToken;

        uint256 price;
        bool isRecoveryMode;
        uint256 totalPricedCollateral;
        uint256 totalDebt;
        (
            collateralToken,
            price,
            totalPricedCollateral,
            totalDebt,
            isRecoveryMode
        ) = _getCollateralAndTCRData(troveManager);
        require(
            !isRecoveryMode,
            "BorrowerOps: Operation not permitted during Recovery Mode"
        );

        (uint256 coll, uint256 debt) = troveManager.applyPendingRewards(
            account
        );

        uint256 newTCR = _getNewTCRFromTroveChange(
            totalPricedCollateral,
            totalDebt,
            coll * price,
            false,
            debt,
            false
        );
        _requireNewTCRisAboveCCR(newTCR);

        troveManager.closeTrove(account, msg.sender, coll, debt);

        // Burn the repaid Debt from the user's balance and the gas compensation from the Gas Pool
        debtToken.burnWithGasCompensation(
            msg.sender,
            debt - DEBT_GAS_COMPENSATION
        );
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(
        ITroveManager _troveManager,
        IERC20 collateralToken,
        address _caller,
        uint256 _maxFeePercentage,
        uint256 _debtAmount
    ) internal returns (uint256) {
        uint256 debtFee = _troveManager.decayBaseRateAndGetBorrowingFee(
            _debtAmount
        );

        _requireUserAcceptsFee(debtFee, _debtAmount, _maxFeePercentage);

        debtToken.mint(ZAI_CORE.feeReceiver(), debtFee);

        emit ZAIEventsLib.BorrowingFeePaid(
            _caller,
            address(collateralToken),
            debtFee
        );

        return debtFee;
    }

    function _getCollChange(
        uint256 _collReceived,
        uint256 _requestedCollWithdrawal
    ) internal pure returns (uint256 collChange, bool isCollIncrease) {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    function _requireValidAdjustmentInCurrentMode(
        uint256 totalPricedCollateral,
        uint256 totalDebt,
        bool _isRecoveryMode,
        uint256 _collWithdrawal,
        bool _isDebtIncrease,
        LocalVariables_adjustTrove memory _vars
    ) internal pure {
        /*
         *In Recovery Mode, only allow:
         *
         * - Pure collateral top-up
         * - Pure debt repayment
         * - Collateral top-up with debt repayment
         * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
         *
         * In Normal Mode, ensure:
         *
         * - The new ICR is above MCR
         * - The adjustment won't pull the TCR below CCR
         */

        // Get the trove's old ICR before the adjustment
        uint256 oldICR = ZaiMath._computeCR(
            _vars.coll,
            _vars.debt,
            _vars.price
        );

        // Get the trove's new ICR after the adjustment
        uint256 newICR = _getNewICRFromTroveChange(
            _vars.coll,
            _vars.debt,
            _vars.collChange,
            _vars.isCollIncrease,
            _vars.netDebtChange,
            _isDebtIncrease,
            _vars.price
        );

        if (_isRecoveryMode) {
            require(
                _collWithdrawal == 0,
                "BorrowerOps: Collateral withdrawal not permitted Recovery Mode"
            );
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(newICR);
                _requireNewICRisAboveOldICR(newICR, oldICR);
            }
        } else {
            // if Normal Mode
            _requireICRisAboveMCR(newICR, _vars.MCR);
            uint256 newTCR = _getNewTCRFromTroveChange(
                totalPricedCollateral,
                totalDebt,
                _vars.collChange * _vars.price,
                _vars.isCollIncrease,
                _vars.netDebtChange,
                _isDebtIncrease
            );
            _requireNewTCRisAboveCCR(newTCR);
        }
    }

    function _requireICRisAboveMCR(uint256 _newICR, uint256 MCR) internal pure {
        require(
            _newICR >= MCR,
            "BorrowerOps: An operation that would result in ICR < MCR is not permitted"
        );
    }

    function _requireICRisAboveCCR(uint256 _newICR) internal pure {
        require(
            _newICR >= CCR,
            "BorrowerOps: Operation must leave trove with ICR >= CCR"
        );
    }

    function _requireNewICRisAboveOldICR(
        uint256 _newICR,
        uint256 _oldICR
    ) internal pure {
        require(
            _newICR >= _oldICR,
            "BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode"
        );
    }

    function _requireNewTCRisAboveCCR(uint256 _newTCR) internal pure {
        require(
            _newTCR >= CCR,
            "BorrowerOps: An operation that would result in TCR < CCR is not permitted"
        );
    }

    function _requireAtLeastMinNetDebt(uint256 _netDebt) internal view {
        require(
            _netDebt >= minNetDebt,
            "BorrowerOps: Trove's net debt must be greater than minimum"
        );
    }

    function _requireValidMaxFeePercentage(
        uint256 _maxFeePercentage
    ) internal pure {
        require(
            _maxFeePercentage <= DECIMAL_PRECISION,
            "Max fee percentage must less than or equal to 100%"
        );
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    ) internal pure returns (uint256) {
        (uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(
            _coll,
            _debt,
            _collChange,
            _isCollIncrease,
            _debtChange,
            _isDebtIncrease
        );

        uint256 newICR = ZaiMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewTroveAmounts(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256, uint256) {
        uint256 newColl = _coll;
        uint256 newDebt = _debt;

        newColl = _isCollIncrease ? _coll + _collChange : _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;

        return (newColl, newDebt);
    }

    function _getNewTCRFromTroveChange(
        uint256 totalColl,
        uint256 totalDebt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256) {
        totalDebt = _isDebtIncrease
            ? totalDebt + _debtChange
            : totalDebt - _debtChange;
        totalColl = _isCollIncrease
            ? totalColl + _collChange
            : totalColl - _collChange;

        uint256 newTCR = ZaiMath._computeCR(totalColl, totalDebt);
        return newTCR;
    }

    function _getTCRData(
        SystemBalances memory balances
    )
        internal
        pure
        returns (
            uint256 amount,
            uint256 totalPricedCollateral,
            uint256 totalDebt
        )
    {
        uint256 loopEnd = balances.collaterals.length;
        for (uint256 i; i < loopEnd; ) {
            totalPricedCollateral += (balances.collaterals[i] *
                balances.prices[i]);
            totalDebt += balances.debts[i];
            unchecked {
                ++i;
            }
        }
        amount = ZaiMath._computeCR(totalPricedCollateral, totalDebt);

        return (amount, totalPricedCollateral, totalDebt);
    }

    function _getCollateralAndTCRData(
        ITroveManager troveManager
    )
        internal
        returns (
            IERC20 collateralToken,
            uint256 price,
            uint256 totalPricedCollateral,
            uint256 totalDebt,
            bool isRecoveryMode
        )
    {
        TroveManagerData storage t = _troveManagersData[troveManager];
        uint256 index;
        (collateralToken, index) = (t.collateralToken, t.index);

        require(
            address(collateralToken) != address(0),
            "Collateral not enabled"
        );

        uint256 amount;
        SystemBalances memory balances = fetchBalances();
        (amount, totalPricedCollateral, totalDebt) = _getTCRData(balances);
        isRecoveryMode = checkRecoveryMode(amount);

        return (
            collateralToken,
            balances.prices[index],
            totalPricedCollateral,
            totalDebt,
            isRecoveryMode
        );
    }

    /// @inheritdoc IBorrowerOperations
    function getGlobalSystemBalances()
        external
        returns (uint256 totalPricedCollateral, uint256 totalDebt)
    {
        SystemBalances memory balances = fetchBalances();
        (, totalPricedCollateral, totalDebt) = _getTCRData(balances);
    }

    function _setMinNetDebt(uint256 _minNetDebt) internal {
        require(_minNetDebt > 0);
        minNetDebt = _minNetDebt;
    }

    /// @inheritdoc IBorrowerOperations
    function troveManagersData(
        ITroveManager what
    ) external view returns (TroveManagerData memory) {
        return _troveManagersData[what];
    }
}
