import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";

async function main(hre: HardhatRuntimeEnvironment) {
  const psm = await hre.deployments.get("PegStabilityModule-USDC");
  const adapter = await hre.deployments.get("ZaiStablecoinOFTAdapter");

  await deployContract(
    hre,
    "L1BridgeCollateralL0",
    [psm.address, adapter.address, config[hre.network.name].libraries.endpoint],
    "L1BridgeCollateralL0"
  );
}

main.tags = ["L1BridgeCollateralL0"];
export default main;
