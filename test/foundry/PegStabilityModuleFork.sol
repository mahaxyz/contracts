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

import {Test, console} from "forge-std/Test.sol";
import {IStablecoin} from "../../contracts/interfaces/IStablecoin.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {PegStabilityModuleYield, IPegStabilityModuleYield} from "../../contracts/core/psm/PegStabilityModuleYield.sol";

contract PegStabilityModuleYieldFork is Test {
  uint256 mainnetFork;
  string public MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
  IStablecoin public USDZ;
  IERC4626 public sUSDe;
  IPegStabilityModuleYield public psm;
  address public GOVERNANCE;
  address public FEEDISTRIBUTOR;
  address public constant ROLE_ADMIN =
    0x690002dA1F2d828D72Aa89367623dF7A432E85A9;

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
    psm.initialize(
      address(USDZ),
      address(sUSDe),
      GOVERNANCE,
     0.9090 * 1e18,
      100_000 * 1e18,
      100_000 * 1e18,
      0,
      100,
      FEEDISTRIBUTOR
    );

    vm.startPrank(ROLE_ADMIN);
    USDZ.grantManagerRole(GOVERNANCE);
    USDZ.grantManagerRole(address(psm));
    USDZ.grantManagerRole(address(this));
    vm.stopPrank();
  }

  function testInitValues() public {
    assertEq(psm.rate(), 1e18);
    assertEq(address(psm.usdz()), address(USDZ));
    assertEq(address(psm.collateral()), address(sUSDe));
    assertEq(psm.feeDistributor(), FEEDISTRIBUTOR);
  }

  function testTransferYieldToFeeDistributor() external {
    // 1. Set up the test account with sUSDe (a whale with sufficient sUSDe)
    address sUSDeWhale = 0xb99a2c4C1C4F1fc27150681B740396F6CE1cBcF5;
    uint256 initialAmount = 10_000 * 1e18; // 9,090.91 sUSDe, representing $10,000 at $1.10 rate

    // 2. Start Prank with whale account to transfer sUSDe to PSM
    vm.startPrank(sUSDeWhale);

    // Ensure sUSDeWhale has enough balance and approve the transfer
    sUSDe.approve(address(psm), UINT256_MAX);

    console.log("Before Balance Collateral", sUSDe.balanceOf(address(psm)));
    uint256 beforeBalance = sUSDe.balanceOf(sUSDeWhale);

    // Transfer sUSDe to the PSM contract
    psm.mint(address(this), initialAmount); // TODO: use user here
    console.log("ZAI", USDZ.balanceOf(address(this)));

    console.log("After Collateral Balance", sUSDe.balanceOf(address(psm))); // ZAI
    console.log("Wahle", sUSDe.balanceOf(address(sUSDeWhale))); // ZAI
    uint256 whaleBalance = sUSDe.balanceOf(address(sUSDeWhale));
    vm.stopPrank();

    // 3. Advance time by 6 months (approximately 180 days)
    uint256 sixMonthsInSeconds = 180 days;
    vm.warp(block.timestamp + sixMonthsInSeconds);

    // 3. Mock price increase after 6 months to $1.155
    uint256 newPrice = 0.865 * 1e18; // Six months later price is $1.155
    console.log("New Rate",newPrice);

    // // Update the rate in the PSM (assuming a price oracle mechanism or manual setting for the test)
    vm.startPrank(GOVERNANCE);
    psm.updateRate(newPrice);
    vm.stopPrank();

    // // Calculate expected yield after price increase
    // uint256 expectedNewValue = (initialAmount * newPrice) / 1e18; // New value of collateral in terms of USD
    // console.log("ExpectedNewValue", expectedNewValue);
    // console.log("CovertToAssets",)
    // uint256 debtValue = 10_000 * 1e18; // Targeted debt value is $10,000
    // console.log("Debt Value", debtValue);

    // uint256 excessValue = expectedNewValue - debtValue;
    // console.log("Excess Value", excessValue);
    // uint256 expectedYieldShares = (excessValue * 1e18) / newPrice;
    // console.log("Expected Yield Shares", expectedYieldShares);

    // // 4. Call transferYieldToFeeDistributor
    psm.transferYieldToFeeDistributor();

    // // 5. Check final balance of feeDistributor
    uint256 feeDistributorBalance = sUSDe.balanceOf(FEEDISTRIBUTOR);
    console.log("Fee Distributor Balance", feeDistributorBalance);
    // assertGe(
    //   feeDistributorBalance,
    //   expectedYieldShares,
    //   "Incorrect yield amount transferred"
    // );

    // // Additional Assertions (Optional)
    // // Ensure the PSM debt remains consistent at the target
    // assertEq(
    //   psm.debt(),
    //   debtValue,
    //   "Debt value should remain at $10,000 equivalent"
    // );
    // // Ensure no additional sUSDe left as yield in the PSM contract beyond target
    // uint256 remainingYield = psm.feesCollected();
    // assertEq(
    //   remainingYield,
    //   0,
    //   "No excess yield should remain in the PSM after transfer"
    // );
  }
}
