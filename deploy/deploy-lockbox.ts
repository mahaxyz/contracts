import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { proxyAdmin } = await getNamedAccounts();

  const zaiD = await deployments.get("ZaiStablecoin");
  const xZaiD = await deployments.get("xZAI-Proxy");

  await deployProxy(
    hre,
    "XERC20Lockbox",
    [xZaiD.address, zaiD.address, false],
    proxyAdmin,
    "xZaiLockbox"
  );
}

main.tags = ["xZaiLockbox"];
export default main;
