import { ethers } from "hardhat";
import hre from "hardhat";
import { deployContract, estimateDeploymentAddress, getDeploymentNonce } from "./utils";
import { BorrowerOperations, DebtToken, Factory, FeeReceiver, LiquidationManager, MultiCollateralHintHelpers, MultiTroveGetter, PriceFeed, PrismaCore, SortedTroves, StabilityPool, TroveManager, TroveManagerGetters } from "../typechain";
import { BigNumber } from "ethers";

async function main() {
  const ethFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306" // Sepolia ETH/USD Chainlink Feed address
  const MIN_NET_DEBT = 200;
  const GAS_COMPENSATION = 10;
  const DEBT_TOKEN_NAME = "Maha Debt";
  const DEBT_TOKEN_SYMBOL = "MDT";
  const e18 = BigNumber.from(10).pow(18);
  const LAYER_ZERO_ENDPOINT = "0x6EDCE65403992e310A62460808c4b910D972f10f"; // Sepolia Endpoint address

  console.log("- Estimating deployment addresses");
  const [signer] = await ethers.getSigners();
  const deployer = await (signer).getAddress();
  const nonce = await getDeploymentNonce(signer);

  const addreses: string[] = [];
  for (let index = 0; index < 13; index++) {
    addreses.push(await estimateDeploymentAddress(deployer, nonce+index));
  }
  const addressList = {
    PrismaCore: addreses[0],
    PriceFeed: addreses[1],
    FeeReceiver: addreses[2],
    Factory: addreses[3],
    DebtToken: addreses[4],
    BorrowerOperations: addreses[5],
    GasPool: addreses[6],
    LiquidationManager: addreses[7],
    StabilityPool: addreses[8],
    TroveManagerGetters: addreses[9],
    SortedTroves: addreses[10],
    TroveManager: addreses[11],
    PrismaVault: addreses[12]
  }

  //// PrismaCore.sol ////
  await deployContract<PrismaCore>("PrismaCore", [
    deployer, // owner
    deployer, // guardian
    addressList.PriceFeed, // priceFeed
    addressList.FeeReceiver, // feeReceiver
  ]);

  //// PriceFeed.sol ////
  await deployContract<PriceFeed>("PriceFeed", [
    addressList.PrismaCore, // prismaCore
    ethFeed, // Sepolia ETH/USD Chainlink Feed address
    []
  ]);

  //// FeeReceiver.sol ////
  await deployContract<FeeReceiver>("FeeReceiver", [
    addressList.PrismaCore,
  ]);

  //// Factory.sol ////
  await deployContract<Factory>("Factory", [
    addressList.PrismaCore, // address _prismaCore,
    addressList.DebtToken, // IDebtToken _debtToken,
    addressList.StabilityPool, // IStabilityPool _stabilityPool,
    addressList.BorrowerOperations, // IBorrowerOperations _borrowerOperations,
    addressList.SortedTroves, // address _sortedTroves,
    addressList.TroveManager, // address _troveManager,
    addressList.LiquidationManager, // ILiquidationManager _liquidationManager
  ]);

  //// BorrowerOperations.sol ////
  await deployContract<BorrowerOperations>("BorrowerOperations", [
    addressList.PrismaCore, // address _prismaCore,
    addressList.DebtToken, // address _debtTokenAddress,
    addressList.Factory, // address _factory,
    e18.mul(MIN_NET_DEBT), // uint256 _minNetDebt,
    GAS_COMPENSATION, // uint256 _gasCompensation
  ]);

  //// DebtToken.sol ////
  await deployContract<DebtToken>("DebtToken", [
    DEBT_TOKEN_NAME, // token name
    DEBT_TOKEN_SYMBOL, // token symbol
    addressList.StabilityPool, // address _stabilityPoolAddress
    addressList.BorrowerOperations, // address _borrowerOperationsAddress
    addressList.PrismaCore, // IPrismaCore prismaCore_,
    LAYER_ZERO_ENDPOINT, // address _layerZeroEndpoint,
    addressList.Factory, // address _factory,
    addressList.GasPool, // address _gasPool,
    GAS_COMPENSATION, // uint256 _gasCompensation
  ]);

  //// GasPool.sol ////
  await deployContract("GasPool");

  //// LiquidationManager.sol ////
  await deployContract<LiquidationManager>("LiquidationManager", [
    addressList.StabilityPool, // IStabilityPool _stabilityPoolAddress,
    addressList.BorrowerOperations, // IBorrowerOperations _borrowerOperations,
    addressList.Factory, // address _factory,
    GAS_COMPENSATION, // uint256 _gasCompensation
  ]);

  //// StabilityPool.sol ////
  await deployContract<StabilityPool>("StabilityPool", [
    addressList.PrismaCore, // address _prismaCore,
    addressList.DebtToken, // IDebtTokenOnezProxy _debtTokenAddress,
    addressList.PrismaVault, // IPrismaVault _vault,
    addressList.Factory, // address _factory,
    addressList.LiquidationManager, // address _liquidationManager
  ]);

  //// MultiCollateralHintHelpers.sol ////
  await deployContract<MultiCollateralHintHelpers>("MultiCollateralHintHelpers",[
    addressList.PrismaCore, 
    GAS_COMPENSATION
  ]);

  //// MultiTroveGetter.sol ////
  await deployContract<MultiTroveGetter>("MultiTroveGetter");

  //// TroveManagerGetters.sol ////
  await deployContract<TroveManagerGetters>("TroveManagerGetters",[
    addressList.Factory
  ]);

  //// SortedTroves.sol ////
  await deployContract<SortedTroves>("SortedTroves");

  //// TroveManager.sol ////
  await deployContract<TroveManager>("TroveManager",[
    addressList.PrismaCore, // address _prismaCore,
    addressList.GasPool, // address _gasPoolAddress,
    addressList.DebtToken, // address _debtTokenAddress,
    addressList.BorrowerOperations, // address _borrowerOperationsAddress,
    addressList.PrismaVault, // address _vault,
    addressList.LiquidationManager, // address _liquidationManager,
    GAS_COMPENSATION, // uint256 _gasCompensation
  ]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
