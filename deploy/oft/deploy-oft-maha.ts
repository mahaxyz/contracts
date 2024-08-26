import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";

async function main(hre: HardhatRuntimeEnvironment) {
  const contract = await deployContract(
    hre,
    "LayerZeroCustomOFT",
    ["MAHA.xyz", "MAHA", config[hre.network.name].libraries.endpoint],
    "MAHAOFT"
  );

  const zai = await hre.ethers.getContractAt(
    "LayerZeroCustomOFT",
    contract.address
  );

  if (!(await hre.deployments.getOrNull("MAHA"))) {
    await hre.deployments.save("MAHA", {
      abi: zai.interface.format(true),
      address: contract.address,
    });
  }
}

main.tags = ["MAHAOFT"];
export default main;
