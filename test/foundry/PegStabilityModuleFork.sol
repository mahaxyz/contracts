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

import {IPegStabilityModuleYield, PegStabilityModuleYield} from "../../contracts/core/psm/PegStabilityModuleYield.sol";
import {IStablecoin} from "../../contracts/interfaces/IStablecoin.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Test, console} from "forge-std/Test.sol";

contract PegStabilityModuleYieldFork is Test {
  uint256 mainnetFork;
  string public MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
  IStablecoin public USDZ;
  IERC4626 public sUSDe;
  PegStabilityModuleYield public psm;
  address public GOVERNANCE;
  address public FEEDISTRIBUTOR;
  address public constant ROLE_ADMIN = 0x690002dA1F2d828D72Aa89367623dF7A432E85A9;

  function setUp() public {
    mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);

    USDZ = IStablecoin(0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0);
    sUSDe = IERC4626(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
    GOVERNANCE = 0x4E88E72bd81C7EA394cB410296d99987c3A242fE;
    FEEDISTRIBUTOR = makeAddr("feeDistributor");

    // Deploy the PSM Contract here
    psm = new PegStabilityModuleYield();

    // Initialize the PSM
    psm.initialize(address(USDZ), address(sUSDe), GOVERNANCE, 100_000 * 1e18, 100_000 * 1e18, 0, 100, FEEDISTRIBUTOR);

    vm.startPrank(ROLE_ADMIN);
    USDZ.grantManagerRole(GOVERNANCE);
    USDZ.grantManagerRole(address(psm));
    USDZ.grantManagerRole(address(this));
    vm.stopPrank();
  }

  function testInitValues() public view {
    assertEq(psm.rate(), 1e18);
    assertEq(address(psm.zai()), address(USDZ));
    assertEq(address(psm.collateral()), address(sUSDe));
    assertEq(psm.feeDestination(), FEEDISTRIBUTOR);
  }

  function testTransferYieldToFeeDistributor() external {
    address sUSDeWhale = 0xb99a2c4C1C4F1fc27150681B740396F6CE1cBcF5;
    uint256 initialAmount = 10_000 ether;

    vm.startPrank(sUSDeWhale);

    sUSDe.approve(address(psm), UINT256_MAX);

    console.log("Before Mint PSM Collateral Balance", sUSDe.balanceOf(address(psm)));

    uint256 exchangeRateBeforeDeposit = psm.rate(); // 1.11
    console.log("Exchange Rate Before Deposit", exchangeRateBeforeDeposit);

    // Transfer sUSDe to the PSM contract
    address alice = makeAddr("alice");
    psm.mint(alice, initialAmount);
    console.log("ZAI Balance of Alice After Mint", USDZ.balanceOf(alice)); //10000

    console.log("After Mint PSM Collateral Balance", sUSDe.balanceOf(address(psm)));

    uint256 sUSDePriceBeforeWhaleDeposit = (sUSDe.balanceOf(address(psm)) * psm.rate()) / 1e18; // 10000

    console.log("sUSDe Price Before Deposit -> ", sUSDePriceBeforeWhaleDeposit);

    vm.stopPrank();

    uint256 sixMonthsInSeconds = 180 days;
    vm.warp(block.timestamp + sixMonthsInSeconds);

    _whaleDepositToVault();

    uint256 feeDistributorBalanceBefore = sUSDe.balanceOf(FEEDISTRIBUTOR);

    console.log("FEE Distributor Before Balance", feeDistributorBalanceBefore);
    uint256 exchangeRateAfterDeposit = psm.rate(); // 1.15
    console.log("After deposit exchange rate should change", exchangeRateAfterDeposit);
    uint256 sUSDePriceAfterWhaleDeposit = (sUSDe.balanceOf(address(psm)) * exchangeRateAfterDeposit) / 1e18;
    console.log("sUSDe Price After Deposit -> ", sUSDePriceAfterWhaleDeposit);
    assertGt(exchangeRateAfterDeposit, exchangeRateBeforeDeposit);
    assertGt(sUSDePriceAfterWhaleDeposit, sUSDePriceBeforeWhaleDeposit);

    psm.transferYieldToFeeDistributor();

    uint256 feeDistributorBalanceAfter = sUSDe.balanceOf(FEEDISTRIBUTOR);
    console.log("Fee Distributor Balance", feeDistributorBalanceAfter);

    assertApproxEqAbs(
      feeDistributorBalanceAfter,
      ((sUSDePriceAfterWhaleDeposit - sUSDePriceBeforeWhaleDeposit) * 1e18) / psm.rate(),
      5,
      "!distributorBalance"
    );

    console.log("After Mint PSM Collateral Balance", sUSDe.balanceOf(address(psm)));
  }

  function testExchangeRate() external {
    uint256 rate1 = psm.rate();
    uint256 sixMonthsInSeconds = 180 days;
    vm.warp(block.timestamp + sixMonthsInSeconds);

    _whaleDepositToVault();
    uint256 rate = psm.rate();
    assertLt(rate, rate1);
  }

  function _whaleDepositToVault() internal {
    // Now Deposit in the vault to change the vault exchage rate
    address USDe = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address WHALE_USDe = 0x88a1493366D48225fc3cEFbdae9eBb23E323Ade3;
    uint256 assetAmount = 1000 ether;

    vm.startPrank(WHALE_USDe);
    IERC20(USDe).approve(address(sUSDe), assetAmount);
    sUSDe.deposit(assetAmount, WHALE_USDe);
    vm.stopPrank();
  }
}
