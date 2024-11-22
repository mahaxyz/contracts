import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { parseEther } from "ethers";
import { deployProxy } from "../../scripts/utils";

const main: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const zaiD = await deployments.get("ZaiStablecoin");

  const collateral = "0x9D39A5DE30e57443BfF2A8307A4256c8797A3497"; // sUSDe
  const governance = deployer;
  const supplyCap = parseEther("10000");
  const debtCap = parseEther("10000");
  const mintFeeBps = 100; //1%
  const redeemFeeBps = 100; // 1%
  const feeDistributorAddress = "0x29482Dbc6e646a9eF517b5381e95ACd5BdC8Af07"; // Collector Proxy

  const params = [
    zaiD.address,
    collateral,
    governance,
    supplyCap,
    debtCap,
    mintFeeBps,
    redeemFeeBps,
    feeDistributorAddress,
  ];

  await deployProxy(
    hre,
    "PegStabilityModuleYield",
    params,
    proxyAdminD.address,
    `PegStabilityModuleYield-sUSDe`
  );
};

export default main;
main.tags = ["PegStabilityModuleYield-SUSDE"];
