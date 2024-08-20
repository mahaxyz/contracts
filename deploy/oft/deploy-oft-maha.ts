import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";

async function main(hre: HardhatRuntimeEnvironment) {
  await deployContract(
    hre,
    "LayerZeroCustomOFT",
    ["MAHA.xyz", "MAHA", config[hre.network.name].libraries.endpoint],
    "MAHAOFT"
  );
}

main.tags = ["MAHAOFT"];
export default main;
