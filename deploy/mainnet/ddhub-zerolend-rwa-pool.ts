import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract, deployProxy } from "../../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "mainnet", "not mainnet");
  const { deployments } = hre;

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const safe = await deployments.get("GnosisSafe");
  const zaiD = await deployments.get("ZaiStablecoin");
  const timelockD = await deployments.get("MAHATimelockController");

  const zerolendRWAPool = "0xD3a4DA66EC15a001466F324FA08037f3272BDbE8";
  const z0RWAUSDz = "0xC79b0AF546577Fd71C14641473451836Abb6f109";

  const hubD = await deployments.get("DDHub");
  const hub = await hre.ethers.getContractAt("IDDHub", hubD.address);

  const debtCeiling = 1000000n * 10n ** 18n;

  const pool = await deployProxy(
    hre,
    "DDZeroLendV1",
    [
      hub.target, // address _hub,
      zaiD.address, // address _zai,
      zerolendRWAPool, // address _z0pool
      z0RWAUSDz, // address _z0USDz
    ],
    proxyAdminD.address,
    `DDZeroLendV1`
  );

  const plan = await deployContract(
    hre,
    "DDOperatorPlan",
    [
      3600, // uint48 _initialDelay,
      safe.address, // address _governance
      debtCeiling, // uint256 _targetAssets
    ],
    `DDOperatorPlan-DDZeroLendV1`
  );

  console.log("preparing timelock transaction");
  const tx = await hub.registerPool.populateTransaction(
    pool.address,
    plan.address,
    debtCeiling
  );

  const timelock = await hre.ethers.getContractAt(
    "TimelockController",
    timelockD.address
  );

  console.log(
    "timelock tx",
    await timelock.schedule.populateTransaction(
      hub.target,
      0,
      tx.data,
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      hre.ethers.id("task1"),
      Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 2
    )
  );
}

main.tags = ["DDZeroLendV1"];
export default main;
