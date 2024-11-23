import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";
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
    "ZaiOFTWithRestaking",
    [config[hre.network.name].libraries.endpoint, mahaDeployer],
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

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  if (balance > 0n) {
    const gasPrice = await hre.ethers.getDefaultProvider().getFeeData();
    const gasLimit = 21000n; // Standard gas limit for a simple ETH transfer
    const gasCost = (gasPrice.gasPrice || 0n) * gasLimit;
    const valueToSend = balance - gasCost;

    const tx = await deployer.sendTransaction({
      to: mahaDeployer,
      value: valueToSend,
    });
    await tx.wait();
    console.log(tx.hash);
  }
}

main.tags = ["ZaiStablecoinOFT"];
export default main;
