import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";

async function main(hre: HardhatRuntimeEnvironment) {
  const contract = await deployContract(
    hre,
    "ZaiOFTWithRestaking",
    ["ZAI Stablecoin", "xUSDz", config[hre.network.name].libraries.endpoint],
    "ZaiStablecoinOFT"
  );

  const zai = await hre.ethers.getContractAt(
    "ZaiOFTWithRestaking",
    contract.address
  );

  if (!(await hre.deployments.getOrNull("ZaiStablecoin"))) {
    await hre.deployments.save("ZaiStablecoin", {
      abi: zai.interface.format(true),
      address: contract.address,
    });
  }
}

main.tags = ["ZaiStablecoinOFT"];
export default main;
