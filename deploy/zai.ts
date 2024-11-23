import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  const [deployer] = await hre.ethers.getSigners();
  assert(
    deployer.address.toLowerCase() ==
      "0x35b6e5db7ccc13ce934763067cb4a86ab41e7665",
    "!deployer"
  );

  const mahaDeployer = "0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b";
  // assert((await deployer.getNonce()) == 0, "!deployer.nonce != 0");

  const contract = await deployContract(
    hre,
    "contracts/core/ZaiStablecoin.sol:ZaiStablecoin",
    [mahaDeployer],
    "ZaiStablecoinOFT"
  );

  const zai = await hre.ethers.getContractAt("ZaiStablecoin", contract.address);

  if (!(await hre.deployments.getOrNull("ZaiStablecoin"))) {
    await hre.deployments.save("ZaiStablecoin", {
      abi: zai.interface.format(true),
      address: contract.address,
    });
  }
}

main.tags = ["ZaiStablecoin"];
export default main;
