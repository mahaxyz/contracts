// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseLocker} from "./BaseLocker.sol";

contract LockerLP is BaseLocker {
    function init(address _token, address _staking) external initializer {
        __BaseLocker_init(
            "Locked ZERO/ETH LP",
            "LP-ZERO",
            _token,
            _staking,
            365 * 86400
        );
    }
}
