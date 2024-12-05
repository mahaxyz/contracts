import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  await deployContract(hre, "BalancesUIHelper", [], `BalancesUIHelper`);
}

main.tags = ["BalancesUIHelper"];
export default main;
