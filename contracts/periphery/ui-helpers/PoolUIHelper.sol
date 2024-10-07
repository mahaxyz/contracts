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

import {IMultiStakingRewardsERC4626} from "../../interfaces/core/IMultiStakingRewardsERC4626.sol";
import {ICurveStableSwapNG} from "../../interfaces/periphery/curve/ICurveStableSwapNG.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract PoolUIHelper {
  IERC20 maha;
  IERC20 zai;
  IERC20 usdc;

  struct PoolInfoResponse {
    uint256 mahaAprE8;
    uint256 mahaRewardsPerYearE18;
    uint256 mahaTotalSupply;
    uint256 mahaUserBalance;
    uint256 poolUsdTVLE8;
    uint256 usdcAprE8;
    uint256 usdcRewardsPerYearE6;
    uint256 usdcTotalSupply;
    uint256 usdcUserBalance;
    uint256 userShareE18;
    uint256 zaiTotalSupply;
    uint256 zaiUserBalance;
  }

  constructor(address _maha, address _zai, address _usdc) {
    maha = IERC20(_maha);
    zai = IERC20(_zai);
    usdc = IERC20(_usdc);
  }

  function getPoolInfo(
    address _stakingPool,
    uint256 _mahaPriceE8,
    address _who
  ) external view returns (PoolInfoResponse memory res) {
    IMultiStakingRewardsERC4626 stakingPool = IMultiStakingRewardsERC4626(_stakingPool);
    IERC4626 stakingPool4626 = IERC4626(_stakingPool);
    ICurveStableSwapNG pool = ICurveStableSwapNG(IERC4626(_stakingPool).asset());

    res.mahaTotalSupply = maha.balanceOf(address(pool));
    res.zaiTotalSupply = zai.balanceOf(address(pool));
    res.usdcTotalSupply = usdc.balanceOf(address(pool));

    res.poolUsdTVLE8 =
      (res.mahaTotalSupply * _mahaPriceE8 / 1e8 + res.usdcTotalSupply * 1e12 + res.zaiTotalSupply) / 1e10;

    uint256 totalSupply = stakingPool4626.totalSupply();
    res.userShareE18 = totalSupply == 0 ? 0 : stakingPool4626.balanceOf(_who) * 1e18 / totalSupply;

    res.mahaUserBalance = res.mahaTotalSupply * res.userShareE18 / 1e18;
    res.usdcUserBalance = res.usdcTotalSupply * res.userShareE18 / 1e18;
    res.zaiUserBalance = res.zaiTotalSupply * res.userShareE18 / 1e18;

    res.mahaRewardsPerYearE18 = stakingPool.rewardRate(maha) * 365 days;
    res.usdcRewardsPerYearE6 = stakingPool.rewardRate(usdc) * 365 days;
    res.mahaAprE8 = res.mahaRewardsPerYearE18 * _mahaPriceE8 / (res.poolUsdTVLE8 * 1e10);
    res.usdcAprE8 = res.usdcRewardsPerYearE6 * 1e10 / res.poolUsdTVLE8;
  }
}
