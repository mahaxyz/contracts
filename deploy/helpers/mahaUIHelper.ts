import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const OmnichainStakingToken = await deployments.get("OmnichainStakingToken");
  console.log(`OmnichainStaking Address ${OmnichainStakingToken.address}`);
  await deployContract(
    hre,
    "MahaUIHelper",
    [OmnichainStakingToken.address],
    "MahaUIHelper"
  );
}

main.tags = ["MahaUIHelper"];
export default main;

