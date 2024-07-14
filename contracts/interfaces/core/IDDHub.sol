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

import {IDDPool} from "./IDDPool.sol";
import {IDDPlan} from "./IDDPlan.sol";
import {IZaiStablecoin} from "../IZaiStablecoin.sol";

interface IDDHub {
    error NotAuthorized();
    error NoOp(IDDPool pool);

    // --- Events ---
    event Wind(IDDPool indexed pool, uint256 amt);
    event Unwind(IDDPool indexed pool, uint256 amt);
    event Fees(IDDPool indexed pool, uint256 amt);

    /**
     * @notice Tracking struct for each of the D3M ilks.
     * @param pool   Contract to access external pool and hold balances
     * @param plan   Contract used to calculate target debt
     * @param tau    Time until you can write off the debt [sec]
     * @param writtenOffDebt Debt write off triggered (1 or 0)
     * @param tic    Timestamp when the pool is caged
     */
    struct PoolInfo {
        IDDPool pool; // Access external pool and holds balances
        IDDPlan plan; // How we calculate target debt
        bool isLive;
        uint256 debt;
        uint256 debtCeiling;
    }

    function exec(IDDPool pool) external;

    function evaluatePoolAction(
        IDDPool pool
    ) external view returns (uint256 toSupply, uint256 toWithdraw);

    function zai() external view returns (IZaiStablecoin);

    function RISK_ROLE() external view returns (bytes32);

    function EXECUTOR_ROLE() external view returns (bytes32);

    function feeCollector() external view returns (address);

    function poolInfos(IDDPool pool) external view returns (PoolInfo memory);

    function globalDebtCeiling() external view returns (uint256);

    function initialize(
        address _feeCollector,
        uint256 _globalDebtCeiling,
        address _zai,
        address _governance
    ) external;

    function registerPool(
        IDDPool pool,
        IDDPlan plan,
        uint256 debtCeiling
    ) external;

    function reduceDebtCeiling(IDDPool pool, uint256 amountToReduce) external;

    function setDebtCeiling(IDDPool pool, uint256 amount) external;

    function setFeeCollector(address who) external;

    function setGlobalDebtCeiling(uint256 amount) external;

    function shutdownPool(IDDPool pool) external;
}
