import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  await deployProxy(
    hre,
    "XERC20",
    ["ZAI Stablecoin", "ZAI", deployer],
    deployer,
    "xZAI"
  );
}
main.tags = ["XERC20"];
export default main;
