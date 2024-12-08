import { task } from "hardhat/config";
import { MAHATimelockController } from "../../types";
import { Addressable, ZeroAddress } from "ethers";
import { waitForTx } from "../../scripts/utils";

task(`migrate-timelock-ownership`).setAction(async (_, hre) => {
  const [deployer] = await hre.ethers.getSigners();

  const safeD = await hre.deployments.get("GnosisSafe");
  const safe = safeD.address;

  const hwWallet = "0xa8E39bBced0E29a07E07826bc61Cc02D597236F2";

  const timelockD = await hre.deployments.get("MAHATimelockController");
  const timelock = await hre.ethers.getContractAt(
    "MAHATimelockController",
    timelockD.address
  );

  // ensure roles of the timelock
  await _checkOrGrant(safe, timelock, "CANCELLER_ROLE");
  await _checkOrGrant(safe, timelock, "EXECUTOR_ROLE");
  await _checkOrGrant(safe, timelock, "PROPOSER_ROLE");
  await _checkOrGrant(hwWallet, timelock, "PROPOSER_ROLE");
  await _checkOrGrant(ZeroAddress, timelock, "EXECUTOR_ROLE");
  await _checkOrGrant(timelock.target, timelock, "DEFAULT_ADMIN_ROLE");

  // revoke all other roles from deployer
  await _checkAndRevoke(deployer.address, timelock, "CANCELLER_ROLE");
  await _checkAndRevoke(deployer.address, timelock, "EXECUTOR_ROLE");
  await _checkAndRevoke(deployer.address, timelock, "PROPOSER_ROLE");
  await _checkAndRevoke(deployer.address, timelock, "DEFAULT_ADMIN_ROLE");
});

const _checkOrGrant = async (
  rcpt: string | Addressable,
  timelock: MAHATimelockController,
  role: string
) => {
  const roleHash = await timelock[role]();
  console.log("checking or granting", role, "role to", rcpt);
  if (await timelock.hasRole(roleHash, rcpt)) {
    console.log(`  ${role} role already granted to ${rcpt}`);
  } else {
    console.log(`  granting ${role} role to ${rcpt}`);
    await waitForTx(await timelock.grantRole(roleHash, rcpt));
  }
};

const _checkAndRevoke = async (
  rcpt: string,
  timelock: MAHATimelockController,
  role: string
) => {
  const roleHash = await timelock[role]();
  console.log("checking or granting", role, "role to", rcpt);
  if (await timelock.hasRole(roleHash, rcpt)) {
    console.log(`  ${role} role granted to ${rcpt}`);
    console.log(`  revoking ${role} role from ${rcpt}`);
    await waitForTx(await timelock.revokeRole(roleHash, rcpt));
  }
};
