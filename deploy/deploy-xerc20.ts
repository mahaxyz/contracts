import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  const proxyAdminD = await deployments.get("ProxyAdmin");

  await deployProxy(
    hre,
    "XERC20",
    ["ZAI Stablecoin", "USDz", deployer],
    proxyAdminD.address,
    "xZAI"
  );
}
main.tags = ["XERC20-ZAI"];
export default main;
