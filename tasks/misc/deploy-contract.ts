import { task } from "hardhat/config";
import { deployContract } from "../../scripts/utils";

task(`deploy-contract`).setAction(async (_, hre) => {
  const contract = await deployContract(
    hre,
    "PegStabilityModuleYield",
    [],
    "PegStabilityModuleYield-Impl"
  );
  console.log(contract.address);
});
