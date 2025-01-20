import hre from "hardhat";
import { deployContract } from "../utils";

async function main() {
  const OmnichainStakingTokenD = await hre.deployments.get(
    "OmnichainStakingToken"
  );

  // Deploy proxies
  await deployContract(
    hre,
    "GovernanceUiHelper",
    [OmnichainStakingTokenD.address],
    "GovernanceUiHelper"
  );
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
