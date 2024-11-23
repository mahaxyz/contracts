import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, run } from "hardhat";

const deploySUSDECollectorCron: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { getNamedAccounts } = hre;

  const { deployer } = await getNamedAccounts();

  // Define addresses for the ODOS router, sUSDz token, and USDC token
  const ODOS_ADDRESS = "0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559";
  const SUSDZ_ADDRESS = "0x69000E468f7f6d6f4ed00cF46f368ACDAc252553";
  const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

  const TransparentProxy = await ethers.getContractFactory(
    "TransparentUpgradeableProxy"
  );

  const sUSDeCollectorCron = await ethers.getContractFactory(
    "SUSDECollectorCron"
  );

  const sUSDeCollectorCronImpl = await sUSDeCollectorCron.deploy();

  await sUSDeCollectorCronImpl.waitForDeployment();

  console.log(
    `sUSDe Implementation ${await sUSDeCollectorCronImpl.getAddress()}`
  );

  const sUSDeCollectorCronProxy = await TransparentProxy.deploy(
    await sUSDeCollectorCronImpl.getAddress(),
    deployer,
    "0x"
  );

  console.log(
    `sUSDeCollectorCronProxy deployed at ${await sUSDeCollectorCronProxy.getAddress()}`
  );

  await sUSDeCollectorCronProxy.waitForDeployment();

  const susdeCollectorCron = await ethers.getContractAt(
    "SUSDECollectorCron",
    await sUSDeCollectorCronProxy.getAddress()
  );

  await susdeCollectorCron.initialize(
    ODOS_ADDRESS,
    SUSDZ_ADDRESS,
    USDC_ADDRESS
  );

  console.log(`Initialized the contract.`)
};

export default deploySUSDECollectorCron;
deploySUSDECollectorCron.tags = ["SUSDECollectorCron"];
