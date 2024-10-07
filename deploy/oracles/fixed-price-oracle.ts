import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  await deployContract(hre, "FixedPriceOracle", [1e8, 8], "FixedPriceOracle");
}

main.tags = ["FixedPriceOracle"];
export default main;
