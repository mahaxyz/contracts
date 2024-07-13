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

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IBorrowerOperations} from "../interfaces/IBorrowerOperations.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {ILiquidationManager} from "../interfaces/ILiquidationManager.sol";
import {ISortedTroves} from "../interfaces/ISortedTroves.sol";
import {IStabilityPool} from "../interfaces/IStabilityPool.sol";
import {ITroveManager} from "../interfaces/ITroveManager.sol";
import {IZaiPermissioned} from "../interfaces/IZaiPermissioned.sol";
import {ZAIEventsLib} from "../interfaces/events/ZAIEventsLib.sol";
import {ZaiOwnable} from "./dependencies/ZaiOwnable.sol";

/**
 * @title Zai Trove Factory
 * @author maha.xyz
 * @notice Deploys cloned pairs of `TroveManager` and `SortedTroves` in order to
 * add new collateral types within the system.
 */
contract Factory is IFactory, ZaiOwnable {
    using Clones for address;

    // fixed single-deployment contracts
    IZaiPermissioned public immutable debtToken;
    IStabilityPool public immutable stabilityPool;
    ILiquidationManager public immutable liquidationManager;
    IBorrowerOperations public immutable borrowerOperations;

    // implementation contracts, redeployed each time via clone proxy
    address public sortedTrovesImpl;
    address public troveManagerImpl;
    address[] public troveManagers;

    constructor(
        address core,
        IZaiPermissioned _debtToken,
        IStabilityPool _stabilityPool,
        IBorrowerOperations _borrowerOperations,
        address _sortedTroves,
        address _troveManager,
        ILiquidationManager _liquidationManager
    ) ZaiOwnable(core) {
        debtToken = _debtToken;
        stabilityPool = _stabilityPool;
        borrowerOperations = _borrowerOperations;
        sortedTrovesImpl = _sortedTroves;
        troveManagerImpl = _troveManager;
        liquidationManager = _liquidationManager;
    }

    /// @inheritdoc IFactory
    function troveManagerCount() external view returns (uint256) {
        return troveManagers.length;
    }

    /// @inheritdoc IFactory
    function deployNewInstance(
        address collateral,
        address priceFeed,
        address customTroveManagerImpl,
        address customSortedTrovesImpl,
        DeploymentParams memory params
    ) external onlyOwner {
        address implementation = customTroveManagerImpl == address(0)
            ? troveManagerImpl
            : customTroveManagerImpl;
        address troveManager = implementation.cloneDeterministic(
            bytes32(bytes20(collateral))
        );
        troveManagers.push(troveManager);

        implementation = customSortedTrovesImpl == address(0)
            ? sortedTrovesImpl
            : customSortedTrovesImpl;
        address sortedTroves = implementation.cloneDeterministic(
            bytes32(bytes20(troveManager))
        );

        ITroveManager(troveManager).setAddresses(
            priceFeed,
            sortedTroves,
            collateral
        );
        ISortedTroves(sortedTroves).setAddresses(troveManager);

        // verify that the oracle is correctly working
        ITroveManager(troveManager).fetchPrice();

        stabilityPool.enableCollateral(IERC20(collateral));
        liquidationManager.enableTroveManager(troveManager);
        debtToken.enableTroveManager(troveManager);
        borrowerOperations.configureCollateral(troveManager, collateral);

        ITroveManager(troveManager).setParameters(
            params.minuteDecayFactor,
            params.redemptionFeeFloor,
            params.maxRedemptionFee,
            params.borrowingFeeFloor,
            params.maxBorrowingFee,
            params.interestRateInBps,
            params.maxDebt,
            params.MCR
        );

        emit ZAIEventsLib.NewDeployment(
            collateral,
            priceFeed,
            troveManager,
            sortedTroves
        );
    }

    /// @inheritdoc IFactory
    function setImplementations(
        address _troveManagerImpl,
        address _sortedTrovesImpl
    ) external onlyOwner {
        troveManagerImpl = _troveManagerImpl;
        sortedTrovesImpl = _sortedTrovesImpl;
    }
}
