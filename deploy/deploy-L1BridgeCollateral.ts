import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";
import { config as connextConfig } from "../tasks/connext/config";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const zaiD = await deployments.get("ZaiStablecoin");
  const usdcD = await deployments.get("USDC");
  const proxyAdminD = await deployments.get("ProxyAdmin");
  const lockbockD = await deployments.get("xZaiLockbox");
  const xzaiD = await deployments.get("xZAI-Stablecoin");
  const psmD = await deployments.get("PegStabilityModule-USDC");

  await deployProxy(
    hre,
    "L1BridgeCollateral",
    [
      zaiD.address, // IERC20 _zai,
      xzaiD.address, // IERC20 _xZai,
      psmD.address, // IPegStabilityModule _psm,
      usdcD.address, // IERC20 _collateral,
      lockbockD.address, // IXERC20Lockbox _lockbox,
      connextConfig.mainnet.connext, // address _connext
    ],
    proxyAdminD.address,
    "L1BridgeCollateral"
  );
}

main.tags = ["L1BridgeCollateral"];
export default main;
