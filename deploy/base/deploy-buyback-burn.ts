import { HardhatRuntimeEnvironment } from "hardhat/types";
import assert = require("assert");
import { deployProxy } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const ODOS_ROUTER_BASE = "0x19cEeAd7105607Cd444F5ad10dd51356436095a1";
  const MAHA = await deployments.get("MAHA");
  const USDC = await deployments.get("USDC");
  const DISTRIBUTOR = deployer;

  const BuyBackBurnProxy = await deployProxy(
    hre,
    "BuyBackBurnMaha",
    [MAHA.address, USDC.address, ODOS_ROUTER_BASE, DISTRIBUTOR],
    deployer,
    "BuyBackBurnMaha"
  );

  console.log(`BuyBack Burn contract deployed to ${BuyBackBurnProxy.address}`);
}

main.tags = ["BuyBackBurn"];
export default main;
