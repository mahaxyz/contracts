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

pragma solidity 0.8.21;

import {ZaiStablecoin} from "../../../contracts/core/ZaiStablecoin.sol";
import {LockerLP} from "../../../contracts/governance/locker/LockerLP.sol";
import {LockerToken} from "../../../contracts/governance/locker/LockerToken.sol";
import {OmnichainStakingLP} from "../../../contracts/governance/locker/staking/OmnichainStakingLP.sol";
import {OmnichainStakingToken} from "../../../contracts/governance/locker/staking/OmnichainStakingToken.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockLayerZero} from "../mocks/MockLayerZero.sol";
import "./BaseZaiTest.sol";

contract BaseGovernanceTest is BaseZaiTest {
  LockerLP lockerLP;
  LockerToken lockerToken;

  OmnichainStakingToken omnichainStakingToken;
  OmnichainStakingLP omnichainStakingLP;

  address distributor = makeAddr("distributor");

  address oracle;
  address aggregator;

  function _setupGovernance() internal {
    _setUpBase();

    lockerLP = new LockerLP();
    lockerToken = new LockerToken();
    omnichainStakingToken = new OmnichainStakingToken();
    omnichainStakingLP = new OmnichainStakingLP();
  }

  function _setupLockers() internal {
    _setupGovernance();

    lockerToken.init(address(maha), address(omnichainStakingToken), address(0));
    omnichainStakingToken.init(address(lockerToken), address(weth), address(maha), 7 days, governance, distributor);

    lockerLP.init(address(maha), address(omnichainStakingToken));
    omnichainStakingLP.init(
      address(lockerToken), address(weth), address(maha), 7 days, oracle, aggregator, governance, distributor
    );
  }
}
