import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const omnichainStakingBase = await deployments.get(
    "OmnichainStakingToken-Proxy"
  );

  await deployContract(
    hre,
    "MahaUIHelper",
    [omnichainStakingBase.address],
    "MahaUIHelper"
  );
}
main.tags = ["MahaUIHelper"];
export default main;
