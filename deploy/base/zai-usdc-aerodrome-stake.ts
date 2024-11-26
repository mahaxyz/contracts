import { deployLpStaking } from "../utils/staking-lp";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;
  const lpD = await deployments.get("LP-Token-ZAIUSDC");
  await deployLpStaking(hre, "Staked ZAI/USDC Pool", "sZAIUSDC", lpD.address);
}

main.tags = ["StakingLPRewards-Aerodrome-ZAI-USDC"];
export default main;
