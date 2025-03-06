import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  await deployContract(hre, "Deployer", [], "Deployer");
}

main.tags = ["Deployer"];
export default main;
