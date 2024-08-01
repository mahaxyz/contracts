import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts } = hre;
  const { deployer, proxyAdmin } = await getNamedAccounts();

  await deployProxy(
    hre,
    "XERC20",
    ["ZAI Stablecoin", "USDz", deployer],
    proxyAdmin,
    "xZAI"
  );
}
main.tags = ["XERC20-ZAI"];
export default main;
