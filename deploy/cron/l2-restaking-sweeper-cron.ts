import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;

  const [deployer] = await hre.ethers.getSigners();

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const usdcD = await deployments.get("USDC");
  const l2DepositCollateralL0 = await deployments.get("L2DepositCollateralL0");

  const params = [
    "0xD55DF40ee700D1999bF3935fC3611a0E2853256f", // address _gelatoooooo,
    usdcD.address, // address _usdc,
    5000 * 1e6, // uint256 _limit,
    l2DepositCollateralL0.address, // address _depositCollateralL0,
    deployer.address, // address _governance
  ];

  await deployProxy(
    hre,
    "L2RestakingSweeperCron",
    params,
    proxyAdminD.address,
    `L2RestakingSweeperCron`
  );
}

main.tags = ["L2RestakingSweeperCron"];
export default main;
