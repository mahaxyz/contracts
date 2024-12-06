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

import {IMultiTokenRewardsWithWithdrawalDelay} from "../../interfaces/core/IMultiTokenRewardsWithWithdrawalDelay.sol";
import {ICurveStableSwapNG} from "../../interfaces/periphery/curve/ICurveStableSwapNG.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract PoolUIHelper {
  IERC20 public maha;
  IERC20 public zai;
  IERC20 public szai;
  IERC20 public usdc;

  struct PoolInfoResponse {
    uint256 mahaAprE8;
    uint256 mahaRewardsPerYearE18;
    uint256 mahaTotalSupply;
    uint256 mahaUserBalance;
    uint256 poolUsdTVLE8;
    uint256 szaiTotalSupply;
    uint256 szaiUserBalance;
    uint256 usdcAprE8;
    uint256 usdcRewardsPerYearE6;
    uint256 usdcTotalSupply;
    uint256 usdcUserBalance;
    uint256 userShareE18;
    uint256 withdrawalAmount;
    uint256 withdrawalTimestamp;
    uint256 zaiTotalSupply;
    uint256 zaiUserBalance;
  }

  constructor(address _maha, address _zai, address _szai, address _usdc) {
    maha = IERC20(_maha);
    zai = IERC20(_zai);
    szai = IERC20(_szai);
    usdc = IERC20(_usdc);
  }

  function getPoolInfo(
    address _stakingPool,
    uint256 _mahaPriceE8,
    address _who
  ) public view returns (PoolInfoResponse memory res) {
    IMultiTokenRewardsWithWithdrawalDelay stakingPool = IMultiTokenRewardsWithWithdrawalDelay(_stakingPool);
    IERC4626 stakingPool4626 = IERC4626(_stakingPool);
    address pool = IERC4626(_stakingPool).asset();

    if (_stakingPool == address(szai)) pool = address(szai);

    res.mahaTotalSupply = maha.balanceOf(pool);
    res.zaiTotalSupply = zai.balanceOf(pool);
    res.szaiTotalSupply = szai.balanceOf(pool);
    res.usdcTotalSupply = usdc.balanceOf(pool);

    res.poolUsdTVLE8 = (
      res.mahaTotalSupply * _mahaPriceE8 / 1e8 + res.usdcTotalSupply * 1e12 + res.zaiTotalSupply + res.szaiTotalSupply
    ) / 1e10;

    uint256 totalSupply = stakingPool4626.totalSupply();
    if (totalSupply > 0) {
      res.userShareE18 = totalSupply == 0 ? 0 : stakingPool4626.balanceOf(_who) * 1e18 / totalSupply;
    }

    res.mahaUserBalance = res.mahaTotalSupply * res.userShareE18 / 1e18;
    res.usdcUserBalance = res.usdcTotalSupply * res.userShareE18 / 1e18;
    res.zaiUserBalance = res.zaiTotalSupply * res.userShareE18 / 1e18;
    res.szaiUserBalance = res.szaiTotalSupply * res.userShareE18 / 1e18;

    res.mahaRewardsPerYearE18 = stakingPool.rewardRate(maha) * 365 days;
    res.usdcRewardsPerYearE6 = stakingPool.rewardRate(usdc) * 365 days;

    if (res.poolUsdTVLE8 > 0) {
      res.mahaAprE8 = res.mahaRewardsPerYearE18 * _mahaPriceE8 / (res.poolUsdTVLE8 * 1e10);
      res.usdcAprE8 = res.usdcRewardsPerYearE6 * 1e10 / res.poolUsdTVLE8;
    }

    res.withdrawalAmount = stakingPool.withdrawalAmount(_who);
    res.withdrawalTimestamp = stakingPool.withdrawalTimestamp(_who);
  }

  function getPoolInfoMultiple(
    address[] calldata _stakingPools,
    uint256 _mahaPricesE8,
    address _who
  ) external view returns (PoolInfoResponse[] memory res) {
    res = new PoolInfoResponse[](_stakingPools.length);
    for (uint256 i = 0; i < _stakingPools.length; i++) {
      res[i] = getPoolInfo(_stakingPools[i], _mahaPricesE8, _who);
    }
  }
}
