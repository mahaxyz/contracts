import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const args = [
    (await deployments.get("L2DepositCollateralL0")).address,
    "0x19cEeAd7105607Cd444F5ad10dd51356436095a1", // address _odos,
  ];

  await deployContract(hre, "ZapMintBase", args, "ZapMintBase");
}

main.tags = ["ZapMintBase"];
export default main;
