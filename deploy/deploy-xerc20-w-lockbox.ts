import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  const zaiD = await deployments.get("ZaiStablecoin");

  const xZaiD = await deployProxy(
    hre,
    "XERC20",
    ["xZai Stablecoin", "xZai", deployer],
    deployer,
    "xZAI"
  );

  await deployProxy(
    hre,
    "XERC20Lockbox",
    [xZaiD.address, zaiD.address, false],
    deployer,
    "xZaiLockbox"
  );
}

main.tags = ["XERC20-Lockbox"];
export default main;
