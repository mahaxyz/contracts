import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract, deployProxy, waitForTx } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const [deployer] = await hre.ethers.getSigners();
  const proxyAdminD = await deployments.get("ProxyAdmin");
  const zaiD = await deployments.get("ZaiStablecoin");
  const vault = "0x8a0D114B72A5ba5ABF37283EF98708945db4423e";

  const hubD = await deployments.get("DDHub");
  const hub = await hre.ethers.getContractAt("DDHub", hubD.address);
  const zai = await hre.ethers.getContractAt("ZaiStablecoin", zaiD.address);

  const debtCeiling = 100000n * 10n ** 18n;

  const pool = await deployProxy(
    hre,
    "DDMetaMorpho",
    [
      hub.target, // address _hub,
      zaiD.address, // address _zai,
      vault, // address _vault
    ],
    proxyAdminD.address,
    `DDMetaMorpho`
  );

  const plan = await deployContract(
    hre,
    "DDOperatorPlan",
    [
      3600, // uint48 _initialDelay,
      deployer.address, // address _governance
    ],
    `DDOperatorPlan`
  );

  await waitForTx(
    await hub.registerPool(pool.address, plan.address, debtCeiling)
  );
  await waitForTx(await zai.grantManagerRole(hub.target));
}

main.tags = ["DDMetaMorpho"];
export default main;
