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

import {StakingLPRewards} from "../../contracts/periphery/staking/StakingLPRewards.sol";
import {BaseZaiTest} from "./base/BaseZaiTest.sol";

contract MultiStakingRewardsERC4626Test is BaseZaiTest {
  StakingLPRewards internal staker;

  function setUp() public {
    _setUpBase();

    staker = new StakingLPRewards();
    staker.initialize("StakingLPRewards", "SLP", address(zai), address(this), address(weth), address(maha), 1 days);

    maha.mint(address(this), 100 ether);
    weth.mint(address(this), 100 ether);

    maha.approve(address(staker), 100 ether);
    weth.approve(address(staker), 100 ether);

    staker.grantRole(staker.DISTRIBUTOR_ROLE(), address(this));
  }

  function test_deposit() public {
    zai.mint(whale, 100 ether);

    // supply into the pool
    vm.startPrank(whale);
    zai.approve(address(staker), 100 ether);
    staker.mint(100 ether, whale);
    vm.stopPrank();

    // notify rewards
    staker.notifyRewardAmount(maha, 100 ether);
    staker.notifyRewardAmount(weth, 10 ether);

    assertEq(staker.totalSupply(), 100 ether);
    assertEq(staker.totalAssets(), 100 ether);

    assertApproxEqAbs(staker.rewardRate(maha), 1_157_407_407_407_407, 1e6);
    assertApproxEqAbs(staker.rewardRate(weth), 115_740_740_740_740, 1e6);
  }
}
