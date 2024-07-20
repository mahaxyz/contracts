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

import "../../../lib/metamorpho/test/forge/helpers/BaseTest.sol";

import {ZaiStablecoin} from "../../../contracts/core/ZaiStablecoin.sol";
import {MockLayerZero} from "../../../contracts/tests/MockLayerZero.sol";
import {MockERC20} from "../../../contracts/tests/MockERC20.sol";
import {BaseZaiTest} from "./BaseZaiTest.t.sol";

contract BaseMorphoTest is BaseZaiTest {
  using MarketParamsLib for MarketParams;
  using Math for uint256;
  using MathLib for uint256;
  using MorphoBalancesLib for IMorpho;
  using MorphoLib for IMorpho;

  address supplier = makeAddr("supplier");
  address borrower = makeAddr("borrower");
  address repayer = makeAddr("repayer");
  address onBehalf = makeAddr("onBehalf");
  address receiver = makeAddr("receiver");
  address allocator = makeAddr("allocator");
  address curator = makeAddr("curator");
  address guardian = makeAddr("guardian");
  address skimRecipient = makeAddr("skimRecipient");
  address morphoOwner = makeAddr("morphoOwner");
  address morphoFeeRecipient = makeAddr("morphoFeeRecipient");

  IMorpho morpho =
    IMorpho(
      deployCode(
        "lib/morpho-blue/out/Morpho.sol/Morpho.json",
        abi.encode(morphoOwner)
      )
    );

  OracleMock oracle = new OracleMock();
  IrmMock irm = new IrmMock();
  IMetaMorpho vault;
  MarketParams[] allMarkets;
  MarketParams idleParams;

  function _setUpMorpho() internal {
    _setUpBase();
    _setupMorpoBlue();
    _setupMetaMorpho();

    vm.label(address(morpho), "morpho");
    vm.label(address(oracle), "oracle");
    vm.label(address(irm), "irm");
  }

  function _setupMorpoBlue() private {
    oracle.setPrice(ORACLE_PRICE_SCALE);
    irm.setApr(0.5 ether); // 50%.
    _setupMorpoBlueMarkets();
  }

  function _setupMorpoBlueMarkets() private {
    idleParams = MarketParams({
      loanToken: address(zai),
      collateralToken: address(0),
      oracle: address(0),
      irm: address(irm),
      lltv: 0
    });

    vm.startPrank(morphoOwner);
    morpho.enableIrm(address(irm));
    morpho.setFeeRecipient(morphoFeeRecipient);

    morpho.enableLltv(0);
    vm.stopPrank();

    morpho.createMarket(idleParams);

    for (uint256 i; i < NB_MARKETS; ++i) {
      uint256 lltv = 0.8 ether / (i + 1);

      MarketParams memory marketParams = MarketParams({
        loanToken: address(zai),
        collateralToken: address(weth),
        oracle: address(oracle),
        irm: address(irm),
        lltv: lltv
      });

      vm.prank(morphoOwner);
      morpho.enableLltv(lltv);
      morpho.createMarket(marketParams);

      allMarkets.push(marketParams);
    }

    allMarkets.push(idleParams); // Must be pushed last.

    vm.startPrank(supplier);
    zai.approve(address(morpho), type(uint256).max);
    weth.approve(address(morpho), type(uint256).max);
    vm.stopPrank();

    vm.prank(borrower);
    weth.approve(address(morpho), type(uint256).max);

    vm.prank(repayer);
    zai.approve(address(morpho), type(uint256).max);
  }

  function _setupMetaMorpho() private {
    vault = IMetaMorpho(
      address(
        new MetaMorpho(
          governance,
          address(morpho),
          1 weeks,
          address(zai),
          "MetaMorpho USDz Vault",
          "MMV-ZAI"
        )
      )
    );

    vm.startPrank(governance);
    vault.setCurator(curator);
    vault.setIsAllocator(allocator, true);
    vault.setFeeRecipient(feeDestination);
    vault.setSkimRecipient(skimRecipient);
    vm.stopPrank();

    _setCap(idleParams, type(uint184).max);

    zai.approve(address(vault), type(uint256).max);
    weth.approve(address(vault), type(uint256).max);

    vm.startPrank(supplier);
    zai.approve(address(vault), type(uint256).max);
    weth.approve(address(vault), type(uint256).max);
    vm.stopPrank();

    vm.startPrank(onBehalf);
    zai.approve(address(vault), type(uint256).max);
    weth.approve(address(vault), type(uint256).max);
    vm.stopPrank();

    for (uint256 i; i < NB_MARKETS; ++i) {
      MarketParams memory marketParams = allMarkets[i];

      // Create some debt on the market to accrue interest.
      zai.mint(supplier, MAX_TEST_ASSETS);

      vm.prank(supplier);
      morpho.supply(marketParams, MAX_TEST_ASSETS, 0, onBehalf, hex"");

      uint256 collateral = uint256(MAX_TEST_ASSETS).wDivUp(marketParams.lltv);
      weth.mint(borrower, collateral);

      vm.startPrank(borrower);
      morpho.supplyCollateral(marketParams, collateral, borrower, hex"");
      morpho.borrow(marketParams, MAX_TEST_ASSETS, 0, borrower, borrower);
      vm.stopPrank();
    }

    _setCap(allMarkets[0], CAP);
    _sortSupplyQueueIdleLast();
  }

  function _idle() internal view returns (uint256) {
    return morpho.expectedSupplyAssets(idleParams, address(vault));
  }

  function _setCap(MarketParams memory marketParams, uint256 newCap) private {
    Id id = marketParams.id();
    uint256 cap = vault.config(id).cap;
    bool isEnabled = vault.config(id).enabled;
    if (newCap == cap) return;

    PendingUint192 memory pendingCap = vault.pendingCap(id);
    if (pendingCap.validAt == 0 || newCap != pendingCap.value) {
      vm.prank(curator);
      vault.submitCap(marketParams, newCap);
    }

    if (newCap < cap) return;

    vm.warp(block.timestamp + vault.timelock());

    vault.acceptCap(marketParams);

    assertEq(vault.config(id).cap, newCap, "_setCap");

    if (newCap > 0) {
      if (!isEnabled) {
        Id[] memory newSupplyQueue = new Id[](vault.supplyQueueLength() + 1);
        for (uint256 k; k < vault.supplyQueueLength(); k++) {
          newSupplyQueue[k] = vault.supplyQueue(k);
        }
        newSupplyQueue[vault.supplyQueueLength()] = id;
        vm.prank(allocator);
        vault.setSupplyQueue(newSupplyQueue);
      }
    }
  }

  function _sortSupplyQueueIdleLast() private {
    Id[] memory supplyQueue = new Id[](vault.supplyQueueLength());

    uint256 supplyIndex;
    for (uint256 i; i < supplyQueue.length; ++i) {
      Id id = vault.supplyQueue(i);
      if (Id.unwrap(id) == Id.unwrap(idleParams.id())) continue;

      supplyQueue[supplyIndex] = id;
      ++supplyIndex;
    }

    supplyQueue[supplyIndex] = idleParams.id();
    ++supplyIndex;

    assembly {
      mstore(supplyQueue, supplyIndex)
    }

    vm.prank(allocator);
    vault.setSupplyQueue(supplyQueue);
  }
}
