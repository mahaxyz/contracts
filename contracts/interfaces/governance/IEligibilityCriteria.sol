// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IEligibilityCriteria {
  function checkEligibility(address who, uint256 stakedUSD) external view returns (uint256 multiplierE18);
}
