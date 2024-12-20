// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IPegStabilityModule} from "contracts/interfaces/core/IPegStabilityModule.sol";
import {IERC4626} from "contracts/interfaces/vault/IERC4626.sol";

import {ZapSafetyPool} from "contracts/periphery/zaps/implementations/ethereum/ZapSafetyPool.sol";
import {USDCVault} from "contracts/vault/USDCVault.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";

interface StableSwap {
  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

contract USDCVaultFork is Test {
  USDCVault public vault;
  IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IERC20 public constant USDE = IERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
  IERC4626 public constant SUSDE = IERC4626(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
  IERC4626 public constant SZAI = IERC4626(0x69000195D5e3201Cf73C9Ae4a1559244DF38D47C);
  IPegStabilityModule public constant PSM = IPegStabilityModule(0x7DCdE153e4cACe9Ca852590d9654c7694388Db54);
  ZapSafetyPool public constant ZAP = ZapSafetyPool(0x7e8503b58f7B734431569A0D3c2Db77c1dbae6e8);
  StableSwap public constant POOL = StableSwap(0x02950460E2b9529D0E00284A5fA2d7bDF3fA4d72);
  string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
  uint256 public mainnetFork;

  function setUp() external {
    // Create Mainnet Fork here
    mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vault = new USDCVault();
    vault.initialize(
      "USDC-SZAI Vault",
      "USDC-SZAI",
      address(USDC),
      address(USDE),
      address(SZAI),
      address(SUSDE),
      address(PSM),
      address(ZAP),
      address(POOL)
    );
  }

  function testInitValuesVault() external view {
    address vaultAddress = vault.asset();
    assertEq(vaultAddress, address(USDC));
  }

  function testVaultDeposit() external {
    // Define the addresses for the whale and the recipient
    address USDCWHALE = 0x412Dd3F282b1FA20d3232d86aE060dEC644249f6;
    address bob = makeAddr("1");
    uint256 depositAmount = 100_000_000; // USDC to deposit
    // Start the prank for the whale (USDCWHALE)
    vm.startPrank(USDCWHALE);
    // Approve Vault to transfer USDC
    USDC.approve(address(vault), depositAmount);
    // Perform the deposit of 100 million USDC into the vault for 'bob'
    vault.deposit(depositAmount, bob);
    vm.stopPrank();
  }

  function testWithdrawVault() external {
    // Define the addresses for the whale and the recipient
    address USDCWHALE = 0x412Dd3F282b1FA20d3232d86aE060dEC644249f6;
    address bob = makeAddr("1");
    address alice = makeAddr("2");
    uint256 depositAmount = 100_000_000; // USDC to deposit
    uint256 withdrawAmount = 50_000_000;
    // Start the prank for the whale (USDCWHALE)
    vm.startPrank(USDCWHALE);
    // Approve Vault to transfer USDC
    USDC.approve(address(vault), depositAmount);
    // Perform the deposit of 100 million USDC into the vault for 'bob'
    vault.deposit(depositAmount, bob);
    vault.withdraw(withdrawAmount, alice, bob);
    vm.stopPrank();
  }
}
