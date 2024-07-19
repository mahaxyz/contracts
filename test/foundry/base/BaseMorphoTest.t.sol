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

contract BaseMorphoTest is BaseTest {
  using Math for uint256;
  using MathLib for uint256;
  using MorphoBalancesLib for IMorpho;
  using MarketParamsLib for MarketParams;

  IMetaMorpho internal vault;

  ZaiStablecoin public zai;
  MockERC20 public usdc;

  address governance = address(0x1);
  address shark = address(0x2);
  address whale = address(0x3);
  address ant = address(0x4);
  address feeDestination = address(0x5);

  function _setupToken() internal {
    MockLayerZero lz = new MockLayerZero();
    zai = new ZaiStablecoin(address(lz), address(0x1));
    usdc = new MockERC20("USD Coin", "USDC", 8);
  }

  function _setupMorpoBlue() internal {
    idleParams = MarketParams({
      loanToken: address(zai),
      collateralToken: address(0),
      oracle: address(0),
      irm: address(irm),
      lltv: 0
    });

    vm.startPrank(MORPHO_OWNER);
    morpho.enableIrm(address(irm));
    morpho.setFeeRecipient(MORPHO_FEE_RECIPIENT);

    morpho.enableLltv(0);
    vm.stopPrank();

    morpho.createMarket(idleParams);

    for (uint256 i; i < NB_MARKETS; ++i) {
      uint256 lltv = 0.8 ether / (i + 1);

      MarketParams memory marketParams = MarketParams({
        loanToken: address(zai),
        collateralToken: address(usdc),
        oracle: address(oracle),
        irm: address(irm),
        lltv: lltv
      });

      vm.prank(MORPHO_OWNER);
      morpho.enableLltv(lltv);
      morpho.createMarket(marketParams);

      allMarkets.push(marketParams);
    }

    allMarkets.push(idleParams); // Must be pushed last.

    vm.startPrank(SUPPLIER);
    zai.approve(address(morpho), type(uint256).max);
    usdc.approve(address(morpho), type(uint256).max);
    vm.stopPrank();

    vm.prank(BORROWER);
    usdc.approve(address(morpho), type(uint256).max);

    vm.prank(REPAYER);
    zai.approve(address(morpho), type(uint256).max);
  }

  function _setupMetaMorpho() internal {
    vault = IMetaMorpho(
      address(
        new MetaMorpho(
          OWNER,
          address(morpho),
          1 weeks,
          address(zai),
          "MetaMorpho USDz Vault",
          "MMV-ZAI"
        )
      )
    );

    vm.startPrank(OWNER);
    vault.setCurator(CURATOR);
    vault.setIsAllocator(ALLOCATOR, true);
    vault.setFeeRecipient(FEE_RECIPIENT);
    vault.setSkimRecipient(SKIM_RECIPIENT);
    vm.stopPrank();

    _setCap(idleParams, type(uint184).max);

    zai.approve(address(vault), type(uint256).max);
    usdc.approve(address(vault), type(uint256).max);

    vm.startPrank(SUPPLIER);
    zai.approve(address(vault), type(uint256).max);
    usdc.approve(address(vault), type(uint256).max);
    vm.stopPrank();

    vm.startPrank(ONBEHALF);
    zai.approve(address(vault), type(uint256).max);
    usdc.approve(address(vault), type(uint256).max);
    vm.stopPrank();

    for (uint256 i; i < NB_MARKETS; ++i) {
      MarketParams memory marketParams = allMarkets[i];

      // Create some debt on the market to accrue interest.

      zai.mint(SUPPLIER, MAX_TEST_ASSETS);

      vm.prank(SUPPLIER);
      morpho.supply(marketParams, MAX_TEST_ASSETS, 0, ONBEHALF, hex"");

      uint256 collateral = uint256(MAX_TEST_ASSETS).wDivUp(marketParams.lltv);
      usdc.mint(BORROWER, collateral);

      vm.startPrank(BORROWER);
      morpho.supplyCollateral(marketParams, collateral, BORROWER, hex"");
      morpho.borrow(marketParams, MAX_TEST_ASSETS, 0, BORROWER, BORROWER);
      vm.stopPrank();
    }

    _setCap(allMarkets[0], CAP);
    _sortSupplyQueueIdleLast();
  }

  function setUpMorpho() public {
    super.setUp();
    _setupToken();
    _setupMorpoBlue();
    _setupMetaMorpho();
  }

  function _idle() internal view returns (uint256) {
    return morpho.expectedSupplyAssets(idleParams, address(vault));
  }

  function _setTimelock(uint256 newTimelock) internal {
    uint256 timelock = vault.timelock();
    if (newTimelock == timelock) return;

    // block.timestamp defaults to 1 which may lead to an unrealistic state: block.timestamp < timelock.
    if (block.timestamp < timelock) vm.warp(block.timestamp + timelock);

    PendingUint192 memory pendingTimelock = vault.pendingTimelock();
    if (pendingTimelock.validAt == 0 || newTimelock != pendingTimelock.value) {
      vm.prank(OWNER);
      vault.submitTimelock(newTimelock);
    }

    if (newTimelock > timelock) return;

    vm.warp(block.timestamp + timelock);

    vault.acceptTimelock();

    assertEq(vault.timelock(), newTimelock, "_setTimelock");
  }

  function _setGuardian(address newGuardian) internal {
    address guardian = vault.guardian();
    if (newGuardian == guardian) return;

    PendingAddress memory pendingGuardian = vault.pendingGuardian();
    if (pendingGuardian.validAt == 0 || newGuardian != pendingGuardian.value) {
      vm.prank(OWNER);
      vault.submitGuardian(newGuardian);
    }

    if (guardian == address(0)) return;

    vm.warp(block.timestamp + vault.timelock());

    vault.acceptGuardian();

    assertEq(vault.guardian(), newGuardian, "_setGuardian");
  }

  function _setFee(uint256 newFee) internal {
    uint256 fee = vault.fee();
    if (newFee == fee) return;

    vm.prank(OWNER);
    vault.setFee(newFee);

    assertEq(vault.fee(), newFee, "_setFee");
  }

  function _setCap(MarketParams memory marketParams, uint256 newCap) internal {
    Id id = marketParams.id();
    uint256 cap = vault.config(id).cap;
    bool isEnabled = vault.config(id).enabled;
    if (newCap == cap) return;

    PendingUint192 memory pendingCap = vault.pendingCap(id);
    if (pendingCap.validAt == 0 || newCap != pendingCap.value) {
      vm.prank(CURATOR);
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
        vm.prank(ALLOCATOR);
        vault.setSupplyQueue(newSupplyQueue);
      }
    }
  }

  function _sortSupplyQueueIdleLast() internal {
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

    vm.prank(ALLOCATOR);
    vault.setSupplyQueue(supplyQueue);
  }
}
