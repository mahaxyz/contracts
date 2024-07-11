import { ethers } from "hardhat";
import { parseUnits } from "ethers";
import { ZERO_ADDRESS } from "./utils";

export async function deployLendingPool() {
  // Contracts are deployed using the first signer/account by default
  const [owner] = await ethers.getSigners();

  // factories
  const SupplyLogic = await ethers.getContractFactory("SupplyLogic");
  const BorrowLogic = await ethers.getContractFactory("BorrowLogic");
  const EModeLogic = await ethers.getContractFactory("EModeLogic");
  const BridgeLogic = await ethers.getContractFactory("BridgeLogic");
  const ConfiguratorLogic = await ethers.getContractFactory(
    "ConfiguratorLogic"
  );
  const PoolLogic = await ethers.getContractFactory("PoolLogic");
  const DefaultReserveInterestRateStrategy = await ethers.getContractFactory(
    "DefaultReserveInterestRateStrategy"
  );
  const AaveProtocolDataProvider = await ethers.getContractFactory(
    "AaveProtocolDataProvider"
  );
  const LiquidationLogic = await ethers.getContractFactory("LiquidationLogic");
  const TestnetERC20 = await ethers.getContractFactory("TestnetERC20");
  const ACLManager = await ethers.getContractFactory("ACLManager");
  const AaveOracle = await ethers.getContractFactory("AaveOracle");
  const EmissionManager = await ethers.getContractFactory("EmissionManager");
  const RewardsController = await ethers.getContractFactory(
    "RewardsController"
  );
  const MockAggregator = await ethers.getContractFactory(
    "contracts/tests/MockAggregator.sol:MockAggregator"
  );
  const PoolAddressesProvider = await ethers.getContractFactory(
    "PoolAddressesProvider"
  );
  const AToken = await ethers.getContractFactory("AToken");
  const StableDebtToken = await ethers.getContractFactory("StableDebtToken");
  const VariableDebtToken = await ethers.getContractFactory(
    "VariableDebtToken"
  );

  const addressesProvider = await PoolAddressesProvider.deploy(
    "0",
    owner.address
  );

  const protocolDataProvider = await AaveProtocolDataProvider.deploy(
    addressesProvider.target
  );
  const borrowLogic = await BorrowLogic.deploy();
  const bridgeLogic = await BridgeLogic.deploy();
  const configuratorLogic = await ConfiguratorLogic.deploy();
  const eModeLogic = await EModeLogic.deploy();
  const liquidationLogic = await LiquidationLogic.deploy();
  const poolLogic = await PoolLogic.deploy();
  const supplyLogic = await SupplyLogic.deploy();

  const FlashLoanLogic = await ethers.getContractFactory("FlashLoanLogic", {
    libraries: {
      BorrowLogic: borrowLogic.target,
    },
  });
  const flashLoanLogic = await FlashLoanLogic.deploy();

  const Pool = await ethers.getContractFactory("Pool", {
    libraries: {
      BorrowLogic: borrowLogic.target,
      BridgeLogic: bridgeLogic.target,
      EModeLogic: eModeLogic.target,
      FlashLoanLogic: flashLoanLogic.target,
      LiquidationLogic: liquidationLogic.target,
      PoolLogic: poolLogic.target,
      SupplyLogic: supplyLogic.target,
    },
  });

  const PoolConfigurator = await ethers.getContractFactory("PoolConfigurator", {
    libraries: {
      ConfiguratorLogic: configuratorLogic.target,
    },
  });

  // setup tokens and mock aggregator
  const erc20 = await TestnetERC20.deploy("WETH", "WETH", 18, owner.address);
  const mockAggregator = await MockAggregator.deploy(1800 * 1e8);

  // 2. Set the MarketId
  await addressesProvider.setMarketId("Testnet");

  // deploy pool
  const poolImpl = await Pool.deploy(addressesProvider.target);
  await poolImpl.initialize(addressesProvider.target);

  // deploy pool configuration
  const poolConfiguratorImpl = await PoolConfigurator.deploy();
  await poolConfiguratorImpl.initialize(addressesProvider.target);

  // deploy acl manager
  await addressesProvider.setACLAdmin(owner.address);
  const aclManager = await ACLManager.deploy(addressesProvider.target);
  await addressesProvider.setACLManager(aclManager.target);
  await aclManager.addPoolAdmin(owner.address);
  await aclManager.addEmergencyAdmin(owner.address);

  // deploy oracle
  const oracle = await AaveOracle.deploy(
    addressesProvider.target,
    [erc20.target],
    [mockAggregator.target],
    ZERO_ADDRESS,
    ZERO_ADDRESS,
    parseUnits("1", 8)
  );
  await addressesProvider.setPriceOracle(oracle);

  // set pool impl
  await addressesProvider.setPoolImpl(poolImpl.target);
  await addressesProvider.setPoolConfiguratorImpl(poolConfiguratorImpl.target);

  const pool = await ethers.getContractAt(
    "Pool",
    await addressesProvider.getPool()
  );
  const configurator = await ethers.getContractAt(
    "PoolConfigurator",
    await addressesProvider.getPoolConfigurator()
  );

  // deploy incentives
  const emissionManager = await EmissionManager.deploy(owner.address);
  const rewardsController = await RewardsController.deploy(
    emissionManager.target
  );
  await rewardsController.initialize(ZERO_ADDRESS);
  await emissionManager.setEmissionAdmin(erc20.target, emissionManager.target);
  await emissionManager.setRewardsController(rewardsController);

  const aToken = await AToken.deploy(pool.target);
  const stableDebtToken = await StableDebtToken.deploy(pool.target);
  const variableDebtToken = await VariableDebtToken.deploy(pool.target);

  const strategyData = {
    name: "rateStrategyVolatileOne",
    optimalUsageRatio: parseUnits("0.45", 27).toString(),
    baseVariableBorrowRate: "0",
    variableRateSlope1: parseUnits("0.07", 27).toString(),
    variableRateSlope2: parseUnits("3", 27).toString(),
    stableRateSlope1: parseUnits("0.07", 27).toString(),
    stableRateSlope2: parseUnits("3", 27).toString(),
    baseStableRateOffset: parseUnits("0.02", 27).toString(),
    stableRateExcessOffset: parseUnits("0.05", 27).toString(),
    optimalStableToTotalDebtRatio: parseUnits("0.2", 27).toString(),
  };

  const strategy = await DefaultReserveInterestRateStrategy.deploy(
    addressesProvider.target,
    strategyData.optimalUsageRatio,
    strategyData.baseVariableBorrowRate,
    strategyData.variableRateSlope1,
    strategyData.variableRateSlope2,
    strategyData.stableRateSlope1,
    strategyData.stableRateSlope2,
    strategyData.baseStableRateOffset,
    strategyData.stableRateExcessOffset,
    strategyData.optimalStableToTotalDebtRatio
  );

  await configurator.initReserves([
    {
      aTokenImpl: aToken.target,
      stableDebtTokenImpl: stableDebtToken.target,
      variableDebtTokenImpl: variableDebtToken.target,
      underlyingAssetDecimals: 18,
      interestRateStrategyAddress: strategy.target,
      underlyingAsset: erc20.target,
      treasury: ZERO_ADDRESS,
      incentivesController: rewardsController.target,
      aTokenName: `ZeroLend z0 TEST`,
      aTokenSymbol: `z0TEST`,
      variableDebtTokenName: `ZeroLend Variable Debt TEST`,
      variableDebtTokenSymbol: `variableDebtTEST`,
      stableDebtTokenName: `ZeroLend Stable Debt TEST`,
      stableDebtTokenSymbol: `stableDebtTEST}`,
      params: "0x10",
    },
  ]);

  await configurator.setReserveBorrowing(erc20.target, true);
  await configurator.configureReserveAsCollateral(
    erc20.target,
    8000,
    8250,
    10500
  );

  return {
    aclManager,
    addressesProvider,
    configurator,
    emissionManager,
    erc20,
    mockAggregator,
    oracle,
    owner,
    pool,
    protocolDataProvider,
    rewardsController,
  };
}
