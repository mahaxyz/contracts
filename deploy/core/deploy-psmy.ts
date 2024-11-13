import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { parseEther } from "ethers";

const deployPegStabilityModuleYield: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { getNamedAccounts} = hre;

  const { deployer } = await getNamedAccounts();

  // Deploy the PegStabilityModuleYield implementation

  const USDZ = "0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0"; // Zai
  const collateral = "0x9D39A5DE30e57443BfF2A8307A4256c8797A3497"; // sUSDe
  const governance = deployer;
  const supplyCap = parseEther("10000");
  const debtCap = parseEther("10000");
  const mintFeeBps = 100; //1% 
  const redeemFeeBps = 100; // 1%
  const feeDistributorAddress = "0x29482Dbc6e646a9eF517b5381e95ACd5BdC8Af07"; // Collector Proxy

  const TransparentProxy = await ethers.getContractFactory(
    "TransparentUpgradeableProxy"
  );

  const PegStabilityModuleYield = await ethers.getContractFactory(
    "PegStabilityModuleYield"
  );

  const pegStabilityModuleYieldImpl = await PegStabilityModuleYield.deploy();

  await pegStabilityModuleYieldImpl.waitForDeployment();

  console.log(
    `Deployed the PSMY Implementation at ${await pegStabilityModuleYieldImpl.getAddress()}`
  );

  const pegStabilityModuleYieldProxy = await TransparentProxy.deploy(
    await pegStabilityModuleYieldImpl.getAddress(),
    deployer,
    "0x"
  );

  await pegStabilityModuleYieldProxy.waitForDeployment();

  console.log(
    `pegStabilityModuleYieldProxy deployed at ${await pegStabilityModuleYieldProxy.getAddress()}`
  );

  const psmy = await ethers.getContractAt(
    "PegStabilityModuleYield",
    await pegStabilityModuleYieldProxy.getAddress()
  );

  await psmy.initialize(
    USDZ,
    collateral,
    governance,
    supplyCap,
    debtCap,
    mintFeeBps,
    redeemFeeBps,
    feeDistributorAddress
  );

  console.log("PegStabilityModuleYield initialized.");
};

export default deployPegStabilityModuleYield;
deployPegStabilityModuleYield.tags = ["PegStabilityModuleYield"];
