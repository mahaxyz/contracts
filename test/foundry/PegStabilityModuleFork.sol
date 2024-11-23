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

import {IPegStabilityModule, PegStabilityModuleYield} from "../../contracts/core/psm/PegStabilityModuleYield.sol";
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
  address public constant ROLE_ADMIN = 0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b;

  function setUp() public {
    mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(21_249_044);

    USDZ = IStablecoin(0x69000dFD5025E82f48Eb28325A2B88a241182CEd);
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
    assertEq(psm.rate(), 890_650_384_866_953_367);
    assertEq(address(psm.zai()), address(USDZ));
    assertEq(address(psm.collateral()), address(sUSDe));
    assertEq(psm.feeDestination(), FEEDISTRIBUTOR);
  }

  function testMint() public {
    assertEq(psm.rate(), 890_650_384_866_953_367);

    address whale = 0xb99a2c4C1C4F1fc27150681B740396F6CE1cBcF5;
    vm.startPrank(whale);

    uint256 balBefore = sUSDe.balanceOf(whale);
    sUSDe.approve(address(psm), UINT256_MAX);
    psm.mint(whale, 1 ether);

    uint256 balAfter = sUSDe.balanceOf(whale);
    assertEq(USDZ.balanceOf(whale), 1 ether);
    assertEq(balBefore - balAfter, 890_650_384_866_953_367);

    vm.stopPrank();
  }

  function testTransferYieldToFeeDistributor() external {
    address sUSDeWhale = 0xb99a2c4C1C4F1fc27150681B740396F6CE1cBcF5;
    uint256 initialAmount = 10_000 ether;

    vm.startPrank(sUSDeWhale);

    sUSDe.approve(address(psm), UINT256_MAX);

    uint256 exchangeRateBeforeDeposit = psm.rate(); // 1.11

    // Transfer sUSDe to the PSM contract
    address alice = makeAddr("alice");
    psm.mint(alice, initialAmount);

    uint256 sUSDePriceBeforeWhaleDeposit = (sUSDe.balanceOf(address(psm)) * psm.rate()) / 1e18; // 10000

    vm.stopPrank();

    uint256 sixMonthsInSeconds = 180 days;
    vm.warp(block.timestamp + sixMonthsInSeconds);

    _whaleDepositToVault();

    uint256 exchangeRateAfterDeposit = psm.rate(); // 1.15
    uint256 sUSDePriceAfterWhaleDeposit = (sUSDe.balanceOf(address(psm)) * exchangeRateAfterDeposit) / 1e18;
    assertLt(exchangeRateAfterDeposit, exchangeRateBeforeDeposit);
    assertLt(sUSDePriceAfterWhaleDeposit, sUSDePriceBeforeWhaleDeposit);

    psm.sweepFees();

    uint256 feeDistributorBalanceAfter = sUSDe.balanceOf(FEEDISTRIBUTOR);

    assertApproxEqAbs(
      feeDistributorBalanceAfter,
      ((sUSDePriceAfterWhaleDeposit - sUSDePriceBeforeWhaleDeposit) * 1e18) / psm.rate(),
      5,
      "!distributorBalance"
    );
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
