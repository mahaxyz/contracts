import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer, proxyAdmin } = await getNamedAccounts();

  const zaiD = await deployments.get("ZaiStablecoin");

  const xZaiD = await deployProxy(
    hre,
    "XERC20",
    ["xZAI Stablecoin", "xUSDz", deployer],
    proxyAdmin,
    "xZAI"
  );

  await deployProxy(
    hre,
    "XERC20Lockbox",
    [xZaiD.address, zaiD.address, false],
    proxyAdmin,
    "xZaiLockbox"
  );
}

main.tags = ["XERC20-Lockbox"];
export default main;
