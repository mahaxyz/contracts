import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  await deployContract(hre, "WAGMIE", [], "WAGMIE");
}

main.tags = ["WAGMIE"];
export default main;
