import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name !== "mainnet", "wrong network");

  const [deployer] = await hre.ethers.getSigners();

  const params = [
    config[hre.network.name].libraries.endpoint, // address _endpoint,
    deployer.address, // address _owner
  ];

  await deployContract(
    hre,
    "OmnichainGovernanceExecutorL2",
    params,
    `OmnichainGovernanceExecutorL2`
  );
}

main.tags = ["OmnichainGovernanceExecutorL2"];
export default main;
