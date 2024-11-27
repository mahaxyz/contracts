import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  const [, , deployer] = await hre.ethers.getSigners();
  assert(
    deployer.address.toLowerCase() ==
      "0xbad5d5073c18f43e986fdcf3c011646f3b481360",
    "!deployer"
  );

  const mahaDeployer = "0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b";

  const contract = await deployContract(
    hre,
    "StakedZaiOFTWithRestaking",
    [config[hre.network.name].libraries.endpoint, mahaDeployer],
    "StakedZaiOFTWithRestaking",
    "0xbAd5D5073c18F43E986FDcF3c011646f3b481360"
  );

  const zai = await hre.ethers.getContractAt(
    "StakedZaiOFTWithRestaking",
    contract.address
  );

  if (!(await hre.deployments.getOrNull("sZAI"))) {
    await hre.deployments.save("sZAI", {
      abi: zai.interface.format(true),
      address: contract.address,
    });
  }
}

main.tags = ["StakedZaiStablecoinOFT"];
export default main;
