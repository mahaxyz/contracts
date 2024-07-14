// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

interface ILPVault is IERC20 {
  struct PermitData {
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct DepositParams {
    // todo
    uint256 deadline;
  }

  struct WithdrawParams {
    // todo
    uint256 deadline;
  }

  function deposit(DepositParams calldata params)
    external
    payable
    returns (uint256 shares, uint128 addedLiquidity, uint256 amount0, uint256 amount1);

  function withdraw(WithdrawParams calldata params) external returns (uint128 removedLiquidity, uint256 amount0, uint256 amount1);

  function stakeEth() external payable;

  function stakeEthAndTokens(uint256 amount, PermitData memory permit) external payable;

  function stakeTokens(uint256 amount, PermitData memory permit) external;

  function totalSupplyLP() external returns (uint256);

  function balanceOfLP(address who) external returns (uint256);

  function claimFees() external returns (uint256);

  function treasury() external returns (address);
}
