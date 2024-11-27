import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  const psm = await hre.deployments.get("PegStabilityModule-sUSDe");
  const adapter = await hre.deployments.get("ZaiStablecoinOFTAdapter");

  assert(
    hre.network.name === "mainnet",
    "This script should only be run on mainnet"
  );

  await deployContract(
    hre,
    "L1BridgeCollateralL0",
    [psm.address, adapter.address],
    "L1BridgeCollateralL0"
  );
}

main.tags = ["L1BridgeCollateralL0"];
export default main;
