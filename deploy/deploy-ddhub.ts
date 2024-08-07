import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const [deployer] = await hre.ethers.getSigners();
  const proxyAdminD = await deployments.get("ProxyAdmin");
  const zaiD = await deployments.get("ZaiStablecoin");
  const safe = "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC";

  const params = [
    safe, // address _feeCollector,
    100000n * 10n ** 18n, // uint256 _globalDebtCeiling,
    zaiD.address, // address _zai,
    deployer.address, // address _governance
  ];

  await deployProxy(hre, "DDHub", params, proxyAdminD.address, `DDHub`);
}

main.tags = ["DeployDDHub"];
export default main;
