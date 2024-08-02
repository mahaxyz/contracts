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

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../../contracts/governance/locker/staking/OmnichainStakingBase.sol"; // Update this path based on your project structure
import {ILocker} from "../../../contracts/interfaces/governance/ILocker.sol";

abstract contract MockLocker is ILocker {
    // Implement the mock functions based on your ILocker interface requirements
    // ...

    function balanceOfNFT(uint256) external view override returns (uint256) {
        return 1000;
    }

    function increaseUnlockTime(uint256, uint256) external override {}
    function increaseAmount(uint256, uint256) external override {}
    function locked(uint256) external view override returns (LockedBalance memory) {
        return LockedBalance({
            amount: 1000,
            end: block.timestamp + 30 days,
            start: block.timestamp,
            power: 100
        });
    }
    function safeTransferFrom(address, address, uint256) external override {}
}

contract OmnichainStakingBaseTest is Test {
    OmnichainStakingBase public staking;
    MockLocker public locker;
    IERC20 public rewardsToken;
    address public distributor = address(0x123);
    address public admin = address(0x1);
    address public user = address(0x2);
    address public otherUser = address(0x3);

    function setUp() public {
        locker = new MockLocker();
        rewardsToken = IERC20(address(new MockERC20()));
        staking = new OmnichainStakingBase();

        staking.__OmnichainStakingBase_init(
            "Omnichain Staking",
            "OST",
            address(locker),
            address(rewardsToken),
            address(new MockPoolVoter()),
            7 days,
            distributor
        );

        staking.transferOwnership(admin);
    }

    function testStakeToken() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        assertEq(staking.balanceOf(user), 1000);
        vm.stopPrank();
    }

    function testUnstakeToken() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        staking.unstakeToken(1);
        assertEq(staking.balanceOf(user), 0);
        vm.stopPrank();
    }

    function testIncreaseLockDuration() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        staking.increaseLockDuration(1, 1 days);
        vm.stopPrank();
    }

    function testIncreaseLockAmount() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        staking.increaseLockAmount(1, 1000);
        vm.stopPrank();
    }

    function testGetReward() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        staking.getReward();
        vm.stopPrank();
    }

    function testNotifyRewardAmount() public {
        vm.startPrank(distributor);
        rewardsToken.approve(address(staking), 1000);
        staking.notifyRewardAmount(1000);
        vm.stopPrank();
    }

    function testSetPoolVoter() public {
        vm.startPrank(admin);
        staking.setPoolVoter(address(0x4));
        vm.stopPrank();
    }

    function testSetRewardDistributor() public {
        vm.startPrank(admin);
        staking.setRewardDistributor(address(0x5));
        vm.stopPrank();
    }

    function testRecoverERC20() public {
        vm.startPrank(admin);
        staking.recoverERC20(address(rewardsToken), 100);
        vm.stopPrank();
    }

    function testGetLockedNftDetails() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        staking.getLockedNftDetails(user);
        vm.stopPrank();
    }

    function testPreventTransfer() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        vm.expectRevert("transfer disabled");
        staking.transfer(otherUser, 100);
        vm.expectRevert("transferFrom disabled");
        staking.transferFrom(user, otherUser, 100);
        vm.stopPrank();
    }

    function testUpdateRewardFor() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        staking.updateRewardFor(user);
        vm.stopPrank();
    }

    function testGetRewardETH() public {
        vm.startPrank(user);
        staking.onERC721Received(user, user, 1, "");
        staking.getRewardETH();
        vm.stopPrank();
    }
}
