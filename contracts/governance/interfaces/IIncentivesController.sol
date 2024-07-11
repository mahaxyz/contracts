// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

interface IIncentivesController {
    function handleAction(
        address _user,
        uint256 _balance,
        uint256 _totalSupply
    ) external;
}
