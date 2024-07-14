// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IRewardDistributor {
    // used to notify a gauge/bribe of a given reward, this can create griefing attacks by extending rewards
    // TODO: rework to weekly resets, _updatePeriod as per v1 bribes
    function notifyRewardAmount(uint256 amount) external returns (bool);
}
