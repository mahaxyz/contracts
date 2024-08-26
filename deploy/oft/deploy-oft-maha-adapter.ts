import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";

async function main(hre: HardhatRuntimeEnvironment) {
  const mahaD = await hre.deployments.get("MAHA");
  await deployContract(
    hre,
    "LayerZeroCustomOFTAdapter",
    [mahaD.address, config[hre.network.name].libraries.endpoint],
    "MAHAOFTAdapter"
  );
}

main.tags = ["MAHAOFTAdapter"];
export default main;
