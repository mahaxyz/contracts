import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy, waitForTx } from "../../scripts/utils";
import { ZeroAddress } from "ethers";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const mahaD = await deployments.get("MAHA");
  const zaiD = await deployments.get("ZaiStablecoinOFT");
  const safe = await deployments.get("GnosisSafe");

  const WETH_BASE = "0x4200000000000000000000000000000000000006";
  const REWARD_DURATION = 86400 * 7; // 7 Days

  const lockerTokenProxyD = await deployProxy(
    hre,
    "LockerToken",
    [],
    proxyAdminD.address,
    "LockerToken",
    deployer,
    true
  );

  // Deploy proxies
  const omnichainStakingTokenProxyD = await deployProxy(
    hre,
    "OmnichainStakingToken",
    [],
    proxyAdminD.address,
    "OmnichainStakingToken",
    deployer,
    true
  );

  const lockerToken = await hre.ethers.getContractAt(
    "LockerToken",
    lockerTokenProxyD.address
  );

  const omnichainStaking = await hre.ethers.getContractAt(
    "OmnichainStakingToken",
    omnichainStakingTokenProxyD.address
  );

  if ((await lockerToken.underlying()) === ZeroAddress) {
    await waitForTx(
      await lockerToken.initialize(
        mahaD.address,
        omnichainStakingTokenProxyD.address,
        ZeroAddress
      )
    );
  }

  if ((await omnichainStaking.rewardsDuration()) === 0n) {
    await waitForTx(
      await omnichainStaking.initialize(
        lockerTokenProxyD.address,
        zaiD.address,
        mahaD.address,
        REWARD_DURATION,
        safe.address,
        deployer
      )
    );
  }
}

main.tags = ["GovernanceToken"];
export default main;
