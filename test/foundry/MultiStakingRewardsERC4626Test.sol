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
    staker.initialize(
      "StakingLPRewards", "SLP", address(zai), address(this), address(weth), address(maha), 1 days, address(0)
    );

    maha.mint(address(this), 100 ether);
    weth.mint(address(this), 100 ether);

    maha.approve(address(staker), 100 ether);
    weth.approve(address(staker), 100 ether);

    zai.mint(whale, 100 ether);
    vm.prank(whale);
    zai.approve(address(staker), 100 ether);

    staker.grantRole(staker.DISTRIBUTOR_ROLE(), address(this));
  }

  function test_deposit() public {
    // supply into the pool
    vm.prank(whale);
    staker.mint(100 ether, whale);

    // notify rewards
    staker.notifyRewardAmount(maha, 100 ether);
    staker.notifyRewardAmount(weth, 10 ether);

    assertEq(staker.totalSupply(), 100 ether);
    assertEq(staker.totalAssets(), 100 ether);

    assertApproxEqAbs(staker.rewardRate(maha), 1_157_407_407_407_407, 1e6);
    assertApproxEqAbs(staker.rewardRate(weth), 115_740_740_740_740, 1e6);

    assertEq(staker.boostedTotalSupply(), 100 ether);

    (uint256 boostedBalance, uint256 boostedTotalSupply) = staker.getBoostedBalance(whale);
    assertEq(boostedBalance, 100 ether);
    assertEq(boostedTotalSupply, 100 ether);
  }

  function test_claimReward() public {
    // supply into the pool
    vm.prank(whale);
    staker.mint(100 ether, whale);

    // notify rewards
    staker.notifyRewardAmount(maha, 100 ether);

    assertApproxEqAbs(staker.rewardRate(maha), 1_157_407_407_407_407, 1e6);
    assertEq(staker.rewardRate(weth), 0);

    assertEq(staker.boostedTotalSupply(), 100 ether);

    vm.warp(block.timestamp + 2 days);

    staker.getReward(whale, maha);
    assertApproxEqAbs(maha.balanceOf(whale), 100 ether, 1e8);

    (uint256 boostedBalance, uint256 boostedTotalSupply) = staker.getBoostedBalance(whale);
    assertEq(boostedBalance, 100 ether);
    assertEq(boostedTotalSupply, 100 ether);
  }

  function test_withdraw() public {
    // supply into the pool
    vm.prank(whale);
    staker.mint(100 ether, whale);

    vm.prank(whale);
    staker.redeem(10 ether, whale, whale);

    assertEq(zai.balanceOf(whale), 10 ether);
    (uint256 boostedBalance, uint256 boostedTotalSupply) = staker.getBoostedBalance(whale);
    assertEq(boostedBalance, 90 ether);
    assertEq(boostedTotalSupply, 90 ether);
  }
}
