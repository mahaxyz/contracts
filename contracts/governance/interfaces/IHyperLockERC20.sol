// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IHyperLockERC20 {
    function stake(address _lpToken, uint256 _amount, uint256 _lock) external;

    function unstake(address _lpToken, uint256 _amount) external;
}
