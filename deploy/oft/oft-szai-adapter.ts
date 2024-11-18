import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";

async function main(hre: HardhatRuntimeEnvironment) {
  const zaiD = await hre.deployments.get("ZaiStablecoin");
  await deployContract(
    hre,
    "LayerZeroCustomOFTAdapter",
    [zaiD.address, config[hre.network.name].endpoint],
    "ZaiStablecoinOFTAdapter"
  );
}

main.tags = ["StakedZaiStablecoinOFTAdapter"];
export default main;
