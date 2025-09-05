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

import "forge-std/Test.sol";
import {LockerToken} from "../../../contracts/governance/locker/LockerToken.sol";
import {OmnichainStakingToken} from "../../../contracts/governance/locker/staking/OmnichainStakingToken.sol";
import {ILocker} from "../../../contracts/interfaces/governance/ILocker.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MockERC20} from "../../../contracts/mocks/MockERC20.sol";
import {IMAHAProxy} from "../../../contracts/governance/MAHAProxy.sol";
import {console} from "forge-std/console.sol";
import { ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// ProxyAdmin interface 
interface IProxyAdmin {
    function upgradeAndCall(ITransparentUpgradeableProxy proxy, address implementation, bytes memory data) external payable;
    function owner() external view returns (address);
}

/**
 * @title LockerMigrationTest
 * @notice Foundry fork test for the locker migration script on Base mainnet
 * @dev Tests migration from old LockerToken to new BaseLocker implementation
 * 
 * To run this test:
 * 1. Set BASE_RPC_URL in your environment variables or .env file
 * 2. Run: forge test --match-contract LockerMigrationTest --fork-url $BASE_RPC_URL -vvv
 * 3. For specific tests: forge test --match-test testFullMigrationProcess --fork-url $BASE_RPC_URL -vvv
 */
contract LockerMigrationTest is Test {
    // Base mainnet fork
    uint256 baseFork;
    
    // Deployed contract addresses on Base mainnet
    address constant OLD_LOCKER_ADDRESS = 0xDAe7CD5AA310C66c555543886DFcD454896Ae2C0;
    address constant MAHA_TOKEN = 0x554bba833518793056CF105E66aBEA330672c0dE;
    address constant MAHA_OWNER = 0x7202136d70026DA33628dD3f3eFccb43F62a2469;
    address constant WETH_BASE = 0x4200000000000000000000000000000000000006;
    uint256 constant REWARD_DURATION = 86400 * 7; // 7 Days
    
    // Contract instances
    LockerToken oldLocker;
    OmnichainStakingToken staking;
    LockerToken newLocker;
    MockERC20 underlyingToken;
    
    // Test actors
    address deployer;
    
    // Migration data structures
    struct MigrationData {
        uint256[] tokenIds;
        uint256[] values;
        uint256[] starts;
        uint256[] ends;
        address[] owners;
        bool[] stakeNFTs;
    }
    
    // Store old locker data for comparison
    struct OldLockData {
        uint256 tokenId;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 power;
        address owner;
        bool isStaked;
    }
    
    function setUp() public {
        // Create Base mainnet fork
        baseFork = vm.createFork("https://mainnet.base.org");
        vm.selectFork(baseFork);

        // Set up test actors
        deployer = makeAddr("deployer");
        
        // Connect to deployed contracts
        oldLocker = LockerToken(OLD_LOCKER_ADDRESS);

        // Deploy mock MAHA token for testing
        underlyingToken = new MockERC20("MAHA", "MAHA", 18);

        // Deploy new BaseLocker implementation for testing
        vm.prank(deployer);
        newLocker = new LockerToken();

        // Deploy new staking
        vm.prank(deployer);
        staking = new OmnichainStakingToken();

        // Initialize new locker
        vm.prank(deployer);
        newLocker.initialize(
            address(underlyingToken),
            address(staking)
        );

        // Initialize new staking
        address[] memory rewardTokens = new address[](2);
        rewardTokens[0] = address(underlyingToken);
        rewardTokens[1] = WETH_BASE;
        
        vm.prank(deployer);
        staking.initialize(
            address(newLocker),
            address(WETH_BASE),
            rewardTokens,
            REWARD_DURATION,
            deployer,
            deployer
        );

        // Label contracts for better debugging
        vm.label(OLD_LOCKER_ADDRESS, "OldLocker");
        vm.label(address(staking), "Staking");
        vm.label(address(newLocker), "NewLocker");
        vm.label(MAHA_TOKEN, "MAHA");
        vm.label(MAHA_OWNER, "MAHA Owner");
        vm.label(deployer, "Deployer"); 
    }

    /**
     * @notice Test the complete migration process with real Base mainnet data
     */
    function testFullMigrationProcess() public {
        // Prepare migration data by scanning the old locker
        (MigrationData memory migrationData, OldLockData[] memory oldLockData) = _prepareMigrationData();

        // Approve once for the total migration to avoid per-iteration allowance overwrites
        vm.startPrank(deployer);

        // Execute migration
        newLocker.migrateLocks(migrationData.tokenIds, migrationData.values, migrationData.starts, migrationData.ends, migrationData.owners, migrationData.stakeNFTs);
        vm.stopPrank();

        // Verify migration results
        _verifyMigrationResults(migrationData, oldLockData);
    }
    
    // ============ Helper Functions ============

    /**
     * @notice Prepare migration data with token ids by scanning the old locker (simplified version)
     */
    function _prepareMigrationData() internal returns (MigrationData memory, OldLockData[] memory) {
        uint256 validTokenCount = 10;

        uint256[] memory tokenIds = new uint256[](validTokenCount);
        uint256[] memory values = new uint256[](validTokenCount);
        uint256[] memory starts = new uint256[](validTokenCount);
        uint256[] memory ends = new uint256[](validTokenCount);
        address[] memory owners = new address[](validTokenCount);
        bool[] memory stakeNFTs = new bool[](validTokenCount);
        
        OldLockData[] memory oldLockData = new OldLockData[](validTokenCount);

        for (uint256 tokenIdLoop = 1; tokenIdLoop <= validTokenCount; tokenIdLoop++) {
            ILocker.LockedBalance memory lockedBalance = oldLocker.locked(tokenIdLoop);
            address nftOwner = oldLocker.ownerOf(tokenIdLoop);
            address actualOwner = nftOwner;
            bool shouldStake = false;

            // Check if token is staked in old staking contract
            if (nftOwner == address(staking)) {
                actualOwner = staking.lockedByToken(tokenIdLoop);
                shouldStake = true;
            }

            // Store old lock data for verification
            oldLockData[tokenIdLoop-1] = OldLockData({
                tokenId: tokenIdLoop,
                amount: lockedBalance.amount,
                start: lockedBalance.start,
                end: lockedBalance.end,
                power: lockedBalance.power,
                owner: actualOwner,
                isStaked: shouldStake
            });

            // Prepare migration data
            tokenIds[tokenIdLoop-1] = tokenIdLoop;
            values[tokenIdLoop-1] = lockedBalance.amount;
            starts[tokenIdLoop-1] = lockedBalance.start;
            ends[tokenIdLoop-1] = lockedBalance.end;
            owners[tokenIdLoop-1] = actualOwner;
            stakeNFTs[tokenIdLoop-1] = shouldStake;

            // Mint MAHA tokens to deployer for migration
            vm.prank(MAHA_OWNER);
            underlyingToken.mint(deployer, lockedBalance.amount);
        }   
        
        return (MigrationData(tokenIds, values, starts, ends, owners, stakeNFTs), oldLockData);
    }
    
    
    /**
     * @notice Verify migration results - all locked details must match the old ones
     */
    function _verifyMigrationResults(MigrationData memory data, OldLockData[] memory oldData) internal view {
        for (uint256 i = 0; i < data.values.length; i++) {
            uint256 newTokenId = data.tokenIds[i];
            OldLockData memory oldLock = oldData[i];
            
            // Get new lock data
            ILocker.LockedBalance memory newLock = newLocker.locked(newTokenId);
            
            // Verify amount matches exactly
            assertEq(newLock.amount, oldLock.amount, "Amount must match");
            
            // Verify start time matches exactly
            assertEq(newLock.start, oldLock.start, "Start time must match");
            
            // Verify end time matches exactly
            assertEq(newLock.end, oldLock.end, "End time must match");
            
            // Verify power matches exactly
            assertEq(newLock.power, oldLock.power, "Power must match");
            
            // Verify ownership
            if (oldLock.isStaked) {
                // If originally staked, NFT should be owned by new staking contract
                address nftOwner = newLocker.ownerOf(newTokenId);
                assertEq(nftOwner, address(staking), "Staked NFT should be owned by staking contract");
                
                // And the actual owner should be mapped in the staking contract
                address stakingOwner = staking.lockedByToken(newTokenId);
                assertEq(stakingOwner, oldLock.owner, "Staking owner must match");
            } else {
                // If not staked, NFT should be owned directly by the user
                address nftOwner = newLocker.ownerOf(newTokenId);
                assertEq(nftOwner, oldLock.owner, "Direct NFT owner must match");
            }
        }
    }
} 