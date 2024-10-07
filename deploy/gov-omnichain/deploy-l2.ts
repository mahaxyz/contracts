// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network base
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network zircuit
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network linea
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network xlayer
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network blast
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network arbitrum
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network blast
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network bsc
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network optimism
// npx hardhat deploy --tags OmnichainGovernanceExecutorL2 --network scroll

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
