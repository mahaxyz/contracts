import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const args = [
    (await deployments.get("StakingLPRewards-sZAIUSDC")).address,
    (await deployments.get("PegStabilityModule-sUSDe")).address,
    (await deployments.get("USDC")).address,
    "0xcf5540fffcdc3d510b18bfca6d2b9987b0772559", // address _odos,
  ];

  await deployContract(hre, "ZapCurvePoolUSDC", args, "ZapCurvePoolUSDC");
}

main.tags = ["ZapCurvePoolUSDC"];
export default main;
