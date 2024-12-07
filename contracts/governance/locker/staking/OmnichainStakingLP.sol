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

import {IAggregatorV3Interface} from "../../../interfaces/governance/IAggregatorV3Interface.sol";
import {ILPOracle} from "../../../interfaces/governance/ILPOracle.sol";
import {OmnichainStakingBase} from "./OmnichainStakingBase.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract OmnichainStakingLP is OmnichainStakingBase {
  using SafeCast for int256;

  ILPOracle public oracleLP;
  IAggregatorV3Interface public oracleMAHA;

  function initialize(
    address _locker,
    address _weth,
    address[] memory _rewardTokens,
    uint256 _rewardsDuration,
    address _lpOracle,
    address _aggreagator,
    address _owner,
    address _distributor
  ) external reinitializer(1) {
    super.__OmnichainStakingBase_init(
      "MAHA LP Voting Power", "MAHAvp-LP", _locker, _weth, _rewardTokens, _rewardsDuration, _distributor
    );

    oracleLP = ILPOracle(_lpOracle);
    oracleMAHA = IAggregatorV3Interface(_aggreagator);

    _transferOwnership(_owner);
  }

  receive() external payable {
    // accept eth in the contract
  }

  /**
   * Calculate voting power based on how much the LP token is worth in ZERO terms
   * @param amount The LP token amount
   */
  function _getTokenPower(uint256 amount) internal view override returns (uint256 power) {
    uint256 lpPrice = oracleLP.getPrice();
    uint256 zeroPrice = oracleMAHA.latestAnswer().toUint256();
    require(zeroPrice > 0 && lpPrice > 0, "!price");
    power = ((lpPrice * amount) / zeroPrice);
  }
}
