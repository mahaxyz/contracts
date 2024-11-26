import { deployLpStaking } from "../utils/staking-lp";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;
  const lpD = await deployments.get("LP-Token-ZAIMAHA");
  await deployLpStaking(hre, "Staked ZAI/MAHA Pool", "sZAIMAHA", lpD.address);
}

main.tags = ["StakingLPRewards-Aerodrome-ZAI-MAHA"];
export default main;
