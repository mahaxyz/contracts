import { MaxUint256 } from "ethers";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract, waitForTx } from "../../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;

  const ODOS_ROUTER_BASE = "0x19cEeAd7105607Cd444F5ad10dd51356436095a1";

  const args = [
    (await deployments.get("StakingLPRewards-sZAIMAHA")).address,
    (await deployments.get("L2DepositCollateralL0")).address,
    (await deployments.get("AerodromeRouter")).address,
    ODOS_ROUTER_BASE,
    (await deployments.get("MAHA")).address,
  ];

  await deployContract(
    hre,
    "ZapAerodromePoolMAHA",
    args,
    "ZapAerodromePoolMAHA"
  );
}

main.tags = ["ZapAerodromePoolMAHA"];
export default main;
