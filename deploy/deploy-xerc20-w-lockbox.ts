import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  const zaiD = await deployments.get("ZaiStablecoin");
  const proxyAdminD = await deployments.get("ProxyAdmin");

  const xZaiD = await deployProxy(
    hre,
    "XERC20",
    ["xZAI Stablecoin", "xUSDz", deployer],
    proxyAdminD.address,
    "xZAI"
  );

  await deployProxy(
    hre,
    "XERC20Lockbox",
    [xZaiD.address, zaiD.address, false],
    proxyAdminD.address,
    "xZaiLockbox"
  );
}

main.tags = ["XERC20-Lockbox"];
export default main;
