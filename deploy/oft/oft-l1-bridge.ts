import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "mainnet", "wrong network");
  const psm = await hre.deployments.get("PegStabilityModule-sUSDe");
  const adapter = await hre.deployments.get("ZaiStablecoinOFTAdapter");

  const odos = "0xcf5540fffcdc3d510b18bfca6d2b9987b0772559"; // address _odos,

  await deployContract(
    hre,
    "L1BridgeCollateralL0",
    [psm.address, adapter.address, odos],
    "L1BridgeCollateralL0"
  );
}

main.tags = ["L1BridgeCollateralL0"];
export default main;
