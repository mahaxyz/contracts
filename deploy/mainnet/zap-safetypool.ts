import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const args = [
    (await deployments.get("sZAI")).address,
    (await deployments.get("ZAI")).address,
    "0xcf5540fffcdc3d510b18bfca6d2b9987b0772559", // address _odos,
  ];

  await deployContract(hre, "ZapSafetyPool", args, "ZapSafetyPool");
}

main.tags = ["ZapSafetyPool"];
export default main;
