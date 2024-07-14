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

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {Constants} from "./Constants.sol";
import {IDDHub} from "../../interfaces/core/IDDHub.sol";
import {IDDPlan} from "../../interfaces/core/IDDPlan.sol";
import {IDDPool} from "../../interfaces/core/IDDPool.sol";
import {IZaiStablecoin} from "../../interfaces/IZaiStablecoin.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title Direct Deposit Hub
 * @author maha.xyz
 * @notice This is the main contract responsible for managing pools.
 * @dev Has permissions to mint/burn ZAI
 */
contract DDHub is
    IDDHub,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @inheritdoc IDDHub
    IZaiStablecoin public zai;

    /// @inheritdoc IDDHub
    bytes32 public RISK_ROLE;

    /// @inheritdoc IDDHub
    bytes32 public EXECUTOR_ROLE;

    /// @inheritdoc IDDHub
    address public feeCollector;

    /// @inheritdoc IDDHub
    uint256 public globalDebtCeiling;

    mapping(IDDPool => PoolInfo) internal _poolInfos;

    /// @inheritdoc IDDHub
    function initialize(
        address _feeCollector,
        uint256 _globalDebtCeiling,
        address _zai,
        address _governance
    ) external reinitializer(1) {
        zai = IZaiStablecoin(_zai);
        feeCollector = _feeCollector;
        globalDebtCeiling = _globalDebtCeiling;

        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
    }

    /// @inheritdoc IDDHub
    function poolInfos(
        IDDPool pool
    ) external view returns (PoolInfo memory info) {
        info = _poolInfos[pool];
    }

    /// @inheritdoc IDDHub
    function exec(IDDPool pool) external nonReentrant onlyRole(EXECUTOR_ROLE) {
        PoolInfo memory info = _poolInfos[pool];
        require(info.plan != IDDPlan(address(0)), "not registered");

        pool.preDebtChange();

        if (!info.isLive) _wipe(pool);
        else _exec(pool, info);

        pool.postDebtChange();
    }

    /// @inheritdoc IDDHub
    function registerPool(
        IDDPool pool,
        IDDPlan plan,
        uint256 debtCeiling
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PoolInfo memory info = PoolInfo({
            pool: pool,
            plan: plan,
            isLive: true,
            debt: 0,
            debtCeiling: debtCeiling
        });

        _poolInfos[pool] = info;
    }

    /// @inheritdoc IDDHub
    function reduceDebtCeiling(
        IDDPool pool,
        uint256 amountToReduce
    ) external onlyRole(RISK_ROLE) {
        PoolInfo storage info = _poolInfos[pool];
        info.debtCeiling -= amountToReduce;
    }

    /// @inheritdoc IDDHub
    function setDebtCeiling(
        IDDPool pool,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PoolInfo storage info = _poolInfos[pool];
        info.debtCeiling = amount;
    }

    /// @inheritdoc IDDHub
    function setFeeCollector(
        address who
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeCollector = who;
    }

    /// @inheritdoc IDDHub
    function setGlobalDebtCeiling(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        globalDebtCeiling = amount;
    }

    /// @inheritdoc IDDHub
    function shutdownPool(IDDPool pool) external onlyRole(RISK_ROLE) {
        PoolInfo storage info = _poolInfos[pool];
        info.isLive = false;
    }

    /// @inheritdoc IDDHub
    function evaluatePoolAction(
        IDDPool pool
    ) public view returns (uint256 toSupply, uint256 toWithdraw) {
        PoolInfo memory info = _poolInfos[pool];

        uint256 currentAssets = pool.assetBalance(); // Should return DAI owned by D3MPool
        uint256 maxWithdraw = Math.min(pool.maxWithdraw(), Constants.SAFEMAX);

        // Determine if it needs to fully unwind due to D3M ilk being caged (but not culled), plan is not active or something
        // wrong is going with the third party and we are entering in the ilegal situation of having less assets than registered
        // It's adding up `WAD` due possible rounding errors
        if (
            !info.isLive ||
            info.plan.active() ||
            currentAssets + Constants.WAD < info.debt
        ) {
            toWithdraw = maxWithdraw;
        } else {
            uint256 maxDebt = info.debtCeiling; //vat.Line();
            uint256 debt = info.debt;
            uint256 targetAssets = info.plan.getTargetAssets(currentAssets);

            // Determine if it needs to withdraw due to:
            toWithdraw = Math.max(
                Math.max(
                    debt > maxDebt ? debt - maxDebt : 0, // pool debt ceiling exceeded
                    debt > globalDebtCeiling ? debt - globalDebtCeiling : 0 // global debt ceiling exceeded
                ),
                targetAssets < currentAssets ? currentAssets - targetAssets : 0 // plan targetAssets not met
            );

            if (toWithdraw > 0) toWithdraw = Math.min(toWithdraw, maxWithdraw);
            else {
                // Determine up to which value to add
                // subtractions are safe as otherwise toUnwind > 0 conditional would be true
                toSupply = Math.min(
                    Math.min(
                        Math.min(
                            maxDebt - debt, // amount to reach ilk debt ceiling
                            globalDebtCeiling - debt // amount to reach global debt ceiling
                        ),
                        targetAssets - currentAssets // plan targetAssets
                    ),
                    pool.maxDeposit() // restricts winding down if the pool has a max deposit
                );
            }
        }
    }

    /**
     * @notice Unwinds a pool. Withdraws all ZAI (or max withdrawable ZAI) and burns it to the ground.
     * @param pool The pool to unwind for
     */
    function _wipe(IDDPool pool) internal {
        uint256 amount = pool.maxWithdraw();
        if (amount > 0) {
            pool.withdraw(amount);
            zai.burn(address(this), amount);
            emit Unwind(pool, amount);
        } else revert NoOp(pool);
    }

    function _sweepFees(IDDPool pool) internal {
        PoolInfo memory info = _poolInfos[pool];
        uint256 balance = pool.assetBalance();
        uint256 balanceBefore = zai.balanceOf(address(pool));

        require(balance >= info.debt, "invaraint balance >= debt");

        // calculate fees
        if (balance <= info.debt) return;
        uint256 fees = balance - info.debt;

        // withdraw the generated fees
        pool.withdraw(fees);

        // invariant check
        uint256 balanceAfter = zai.balanceOf(address(pool));
        require(fees == balanceBefore - balanceAfter, "invaraint fees");

        // send the fees to the fee collector
        zai.transfer(feeCollector, fees);
        emit Fees(pool, fees);
    }

    function _exec(IDDPool pool, PoolInfo memory info) internal {
        // collect all the fees
        _sweepFees(pool);

        // Determine if it needs to supply or withdraw
        (uint256 toWithdraw, uint256 toSupply) = evaluatePoolAction(pool);

        if (toWithdraw > 0) {
            pool.withdraw(toWithdraw);
            zai.burn(address(this), toWithdraw);
            emit Unwind(pool, toWithdraw);
        } else if (toSupply > 0) {
            require(
                info.debt + toSupply <= Constants.SAFEMAX,
                "D3MHub/wind-overflow"
            );
            zai.mint(address(this), toSupply);
            pool.deposit(toSupply);
            emit Wind(pool, toSupply);
        } else revert NoOp(pool);
    }
}
