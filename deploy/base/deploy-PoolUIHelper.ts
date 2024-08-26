import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");

  const { deployments } = hre;

  const usdcD = await deployments.get("USDC");
  const mahaD = await deployments.get("MAHAOFT");
  const zaiD = await deployments.get("ZaiStablecoin");

  await deployContract(
    hre,
    "PoolUIHelper",
    [mahaD.address, zaiD.address, usdcD.address],
    `PoolUIHelper`
  );
}

main.tags = ["PoolUIHelper-base"];
export default main;
