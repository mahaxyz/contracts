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

import {IBorrowerOperations} from "./IBorrowerOperations.sol";
import {IZaiBase} from "./IZaiBase.sol";
import {IStabilityPool} from "./IStabilityPool.sol";
import {ITroveManager} from "./ITroveManager.sol";

interface ILiquidationManager is IZaiBase {
    function batchLiquidateTroves(
        ITroveManager troveManager,
        address[] calldata _troveArray
    ) external;

    function enableTroveManager(ITroveManager troveManager) external;

    function liquidate(ITroveManager troveManager, address borrower) external;

    function liquidateTroves(
        ITroveManager troveManager,
        uint256 maxTrovesToLiquidate,
        uint256 maxICR
    ) external;

    function borrowerOperations() external view returns (IBorrowerOperations);

    function factory() external view returns (address);

    function stabilityPool() external view returns (IStabilityPool);
}
