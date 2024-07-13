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

import {IZaiOwnable} from "./IZaiOwnable.sol";
import {IBorrowerOperations} from "./IBorrowerOperations.sol";
import {IZaiPermissioned} from "./IZaiPermissioned.sol";
import {ILiquidationManager} from "./ILiquidationManager.sol";
import {IStabilityPool} from "./IStabilityPool.sol";

interface IFactory is IZaiOwnable {
    // commented values are suggested default parameters
    struct DeploymentParams {
        uint256 minuteDecayFactor; // 999037758833783000  (half life of 12 hours)
        uint256 redemptionFeeFloor; // 1e18 / 1000 * 5  (0.5%)
        uint256 maxRedemptionFee; // 1e18  (100%)
        uint256 borrowingFeeFloor; // 1e18 / 1000 * 5  (0.5%)
        uint256 maxBorrowingFee; // 1e18 / 100 * 5  (5%)
        uint256 interestRateInBps; // 100 (1%)
        uint256 maxDebt;
        uint256 MCR; // 12 * 1e17  (120%)
    }

    /**
     * @notice Deploy new instances of `TroveManager` and `SortedTroves`, adding
     * a new collateral type to the system.
     * @dev When using the default `PriceFeed`, ensure it is configured correctly
     * prior to calling this function. After calling this function, the owner should also call `Vault.registerReceiver`
     * to enable ZAI emissions on the newly deployed `TroveManager`
     * @param collateral Collateral token to use in new deployment
     * @param priceFeed Custom `PriceFeed` deployment. Leave as `address(0)` to use the default.
     * @param customTroveManagerImpl Custom `TroveManager` implementation to clone from. Leave as `address(0)` to use the default.
     * @param customSortedTrovesImpl Custom `SortedTroves` implementation to clone from. Leave as `address(0)` to use the default.
     * @param params Struct of initial parameters to be set on the new trove manager
     */
    function deployNewInstance(
        address collateral,
        address priceFeed,
        address customTroveManagerImpl,
        address customSortedTrovesImpl,
        DeploymentParams calldata params
    ) external;

    function setImplementations(
        address _troveManagerImpl,
        address _sortedTrovesImpl
    ) external;

    function borrowerOperations() external view returns (IBorrowerOperations);

    function debtToken() external view returns (IZaiPermissioned);

    function liquidationManager() external view returns (ILiquidationManager);

    function sortedTrovesImpl() external view returns (address);

    function stabilityPool() external view returns (IStabilityPool);

    function troveManagerCount() external view returns (uint256);

    function troveManagerImpl() external view returns (address);

    function troveManagers(uint256) external view returns (address);
}
