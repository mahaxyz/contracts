import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  const zaiD = await hre.deployments.get("ZaiStablecoin");
  assert(
    hre.network.name === "mainnet",
    "This script should only be run on mainnet"
  );

  await deployContract(
    hre,
    "LayerZeroCustomOFTAdapter",
    [zaiD.address, config[hre.network.name].libraries.endpoint],
    "ZaiStablecoinOFTAdapter"
  );
}

main.tags = ["ZaiStablecoinOFTAdapter"];
export default main;
