import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../scripts/utils";
import { config } from "../tasks/layerzero/config";

async function main(hre: HardhatRuntimeEnvironment) {
  await deployContract(
    hre,
    "LayerZeroCustomOFT",
    ["ZAI Stablecoin (OFT)", "USDz", config[hre.network.name].endpoint],
    "ZaiStablecoinOFT"
  );
}

main.tags = ["ZaiStablecoinOFT"];
export default main;
