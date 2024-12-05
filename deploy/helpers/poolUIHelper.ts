import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const usdcD = await deployments.get("USDC");
  const mahaD = await deployments.get("MAHA");
  const zaiD = await deployments.get("ZaiStablecoin");
  const sZAID = await deployments.get("sZAI");

  await deployContract(
    hre,
    "PoolUIHelper",
    [mahaD.address, zaiD.address, sZAID.address, usdcD.address],
    `PoolUIHelper`
  );
}

main.tags = ["PoolUIHelper"];
export default main;
