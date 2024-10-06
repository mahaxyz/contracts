import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "mainnet", "Wrong network");
  const { deployments } = hre;

  const [deployer] = await hre.ethers.getSigners();

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const usdcD = await deployments.get("USDC");
  const l2DepositCollateralL0 = await deployments.get("L1BridgeCollateralL0");

  const params = [
    usdcD.address, // address _usdc,
    15000 * 1e6, // uint256 _limit,
    l2DepositCollateralL0.address, // address _depositCollateralL0,
    deployer.address, // address _governance
  ];

  await deployProxy(
    hre,
    "L1RestakingSweeperCron",
    params,
    proxyAdminD.address,
    `L1RestakingSweeperCron`
  );
}

main.tags = ["L1RestakingSweeperCron"];
export default main;
