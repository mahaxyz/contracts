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

import {IntegrationTest} from "../../lib/metamorpho/test/forge/helpers/IntegrationTest.sol";

contract BaseMorphoTest is IntegrationTest {
  using Math for uint256;
  using MathLib for uint256;
  using MarketParamsLib for MarketParams;

  address vault = address(0x1);
  address morpho = address(0x2);

  ZaiStablecoin public zai;

  MockERC20 public usdc;
  MockERC20 public dai;
  MockERC20 public weth;

  address governance = address(0x1);
  address shark = address(0x2);
  address whale = address(0x3);
  address ant = address(0x4);
  address feeDestination = address(0x5);

  function setUp() public override {
    super.setUp();

    _setFee(FEE);

    for (uint256 i; i < NB_MARKETS; ++i) {
      MarketParams memory marketParams = allMarkets[i];

      // Create some debt on the market to accrue interest.

      loanToken.setBalance(SUPPLIER, MAX_TEST_ASSETS);

      vm.prank(SUPPLIER);
      morpho.supply(marketParams, MAX_TEST_ASSETS, 0, ONBEHALF, hex"");

      uint256 collateral = uint256(MAX_TEST_ASSETS).wDivUp(marketParams.lltv);
      collateralToken.setBalance(BORROWER, collateral);

      vm.startPrank(BORROWER);
      morpho.supplyCollateral(marketParams, collateral, BORROWER, hex"");
      morpho.borrow(marketParams, MAX_TEST_ASSETS, 0, BORROWER, BORROWER);
      vm.stopPrank();
    }

    _setCap(allMarkets[0], CAP);
    _sortSupplyQueueIdleLast();
  }

  function testSetFee(uint256 fee) public {
    fee = bound(fee, 0, ConstantsLib.MAX_FEE);
    vm.assume(fee != vault.fee());

    vm.expectEmit(address(vault));
    emit EventsLib.SetFee(OWNER, fee);
    vm.prank(OWNER);
    vault.setFee(fee);

    assertEq(vault.fee(), fee, "fee");
  }
}
