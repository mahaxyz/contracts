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
import {MockOmnichainStaking} from "./mocks/MockOmnichainStaking.sol";

contract MultiStakingRewardsERC4626BoostedTest is BaseZaiTest {
  StakingLPRewards internal staker;
  MockOmnichainStaking internal votingPower;

  function setUp() public {
    _setUpBase();

    votingPower = new MockOmnichainStaking();
    staker = new StakingLPRewards();

    staker.initialize(
      "StakingLPRewards", "SLP", address(zai), address(this), address(weth), address(maha), 1 days, address(votingPower)
    );
    votingPower.init();

    maha.mint(address(this), 100 ether);
    weth.mint(address(this), 100 ether);

    maha.approve(address(staker), 100 ether);
    weth.approve(address(staker), 100 ether);

    staker.grantRole(staker.DISTRIBUTOR_ROLE(), address(this));

    _mint_zai(whale);
    _mint_zai(ant);
    _mint_zai(shark);
  }

  function _mint_zai(address to) public {
    zai.mint(to, 100 ether);
    vm.prank(to);
    zai.approve(address(staker), 100 ether);
  }

  function _mint_voting_power() public {
    votingPower.mint(shark, 10 ether);
    votingPower.mint(whale, 1000 ether);
  }

  function test_deposit_with_boost() public {
    _mint_voting_power();

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
  }

  function test_boost_without_stakers() public {
    assertEq(staker.totalBoostedSupply(), 0);

    // supply into the pool
    vm.prank(whale);
    staker.mint(100 ether, whale);

    assertEq(staker.totalBoostedSupply(), 100 ether);

    vm.prank(whale);
    staker.redeem(10 ether, whale, whale);

    assertEq(staker.totalBoostedSupply(), 90 ether);
  }

  function test_boost_as_user_with_one_staker_participating() public {
    _mint_voting_power();
    assertEq(staker.totalBoostedSupply(), 0);
    assertEq(staker.totalSupply(), 0);

    // supply into the pool
    vm.prank(ant);
    staker.mint(100 ether, ant);
    staker.forceUpdateRewards(maha, ant);

    assertEq(staker.totalSupply(), 100 ether, "!totalSupply");
    assertEq(staker.boostedBalance(ant), 20 ether, "!boostedBalance");
    assertEq(staker.totalBoostedSupply(), 20 ether, "!totalBoostedSupply");
    assertEq(staker.balanceOf(ant), 100 ether, "!balanceOf");
    assertEq(staker.votingPower(ant), 0 ether, "!votingPower");

    vm.prank(ant);
    staker.redeem(10 ether, ant, ant);
    staker.forceUpdateRewards(maha, ant);

    assertEq(staker.totalBoostedSupply(), 18 ether, "!totalBoostedSupply after redeem");
    assertEq(staker.boostedBalance(ant), 18 ether, "!boostedBalance after redeem");
    assertEq(staker.balanceOf(ant), 90 ether, "!balanceOf after redeem");
    assertEq(staker.votingPower(ant), 0 ether, "!votingPower");
  }

  function test_boost_as_user_who_stakes_with_one_staker_participating() public {
    test_boost_as_user_with_one_staker_participating();

    votingPower.mint(ant, 10 ether);
    staker.forceUpdateRewards(maha, ant);

    assertEq(staker.totalBoostedSupply(), 90 ether, "!totalBoostedSupply after stake");
    assertEq(staker.boostedBalance(ant), 90 ether, "!boostedBalance after stake");
    assertEq(staker.balanceOf(ant), 90 ether, "!balanceOf after stake");
  }

  function test_boost_with_multiple_stakers_participating() public {
    _mint_voting_power();
    assertEq(staker.totalBoostedSupply(), 0);

    // supply into the pool
    vm.prank(whale);
    staker.mint(100 ether, whale);

    assertEq(staker.totalBoostedSupply(), 100 ether);

    vm.prank(whale);
    staker.redeem(10 ether, whale, whale);

    assertEq(staker.totalBoostedSupply(), 90 ether);
  }

  function test_boostedBalance_without_stakers() public {
    assertEq(staker.boostedBalance(whale), 0);

    // supply into the pool
    vm.prank(whale);
    staker.mint(100 ether, whale);

    assertEq(staker.boostedBalance(whale), 100 ether);

    vm.prank(whale);
    staker.redeem(10 ether, whale, whale);

    assertEq(staker.boostedBalance(whale), 90 ether);
  }
}
