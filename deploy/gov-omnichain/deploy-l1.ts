// npx hardhat deploy --tags OmnichainProposalSenderL1 --network mainnet

import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "mainnet", "wrong network");
  const [deployer] = await hre.ethers.getSigners();

  const params = [
    config[hre.network.name].libraries.endpoint, // address _endpoint,
    deployer.address, // address _owner
  ];

  await deployContract(
    hre,
    "OmnichainProposalSenderL1",
    params,
    `OmnichainProposalSenderL1`
  );
}

main.tags = ["OmnichainProposalSenderL1"];
export default main;
