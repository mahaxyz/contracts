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

import {IZaiStablecoin} from '../IZaiStablecoin.sol';
import {IDDPlan} from './IDDPlan.sol';
import {IDDPool} from './IDDPool.sol';

/**
 * @title Direct Deposit Hub
 * @author maha.xyz
 * @notice This is the main contract responsible for managing pools.
 */
interface IDDHub {
  error NotAuthorized();
  error NoOp(IDDPool pool);

  /**
   * @notice Tracking struct for each of the DD Pools
   * @param plan Contract used to calculate target debt
   * @param isLive Is the pool active
   * @param debt How much debt is currently in the pool
   * @param debtCeiling How much debt can the pool hold
   */
  struct PoolInfo {
    IDDPlan plan;
    bool isLive;
    uint256 debt;
    uint256 debtCeiling;
  }

  function exec(IDDPool pool) external;

  function evaluatePoolAction(IDDPool pool) external view returns (uint256 toSupply, uint256 toWithdraw);

  function zai() external view returns (IZaiStablecoin);

  function RISK_ROLE() external view returns (bytes32);

  function EXECUTOR_ROLE() external view returns (bytes32);

  function feeCollector() external view returns (address);

  function poolInfos(IDDPool pool) external view returns (PoolInfo memory);

  function globalDebtCeiling() external view returns (uint256);

  function initialize(address _feeCollector, uint256 _globalDebtCeiling, address _zai, address _governance) external;

  function registerPool(IDDPool pool, IDDPlan plan, uint256 debtCeiling) external;

  function reduceDebtCeiling(IDDPool pool, uint256 amountToReduce) external;

  function setDebtCeiling(IDDPool pool, uint256 amount) external;

  function setFeeCollector(address who) external;

  function setGlobalDebtCeiling(uint256 amount) external;

  function shutdownPool(IDDPool pool) external;
}
