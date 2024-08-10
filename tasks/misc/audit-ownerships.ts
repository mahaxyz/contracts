import { task } from "hardhat/config";
import { AccessControlEnumerableUpgradeable } from "../../types";
import { Deployment } from "hardhat-deploy/dist/types";

const green = (msg: string) => `\x1b[32m${msg}\x1b[0m`;
const red = (msg: string) => `\x1b[31m${msg}\x1b[0m`;
const blue = (msg: string) => `\x1b[34m${msg}\x1b[0m`;
const boolVal = (val: boolean) => (val ? green("true") : red("false"));

task(
  `audit-ownerships`,
  `Checks if the protocol contracts are owned by the right addresses`
).setAction(async (_, hre) => {
  const deployments = await hre.deployments.all();
  const [deployer] = await hre.ethers.getSigners();

  const roles = [
    "CANCELLER_ROLE",
    "DEFAULT_ADMIN_ROLE",
    "DISTRIBUTOR_ROLE",
    "EXECUTOR_ROLE",
    "MANAGER_ROLE",
    "OPERATOR_ROLE",
    "PROPOSER_ROLE",
    "RISK_ROLE",
  ];

  const safe = "0x6357edbfe5ada570005ceb8fad3139ef5a8863cc";
  const timelock = await hre.deployments.get("MAHATimelockController");

  const deploymentNames = Object.keys(deployments);
  const proxyAdmin = await hre.deployments.get("ProxyAdmin");

  const isOwnable = (deployment: Deployment) =>
    deployment.abi.findIndex((abi: any) => abi.name === "owner") >= 0;

  const isProxy = (deployment: Deployment) =>
    deployment.abi.findIndex(
      (abi: any) =>
        abi.name === "proxyAdmin" ||
        abi == "function proxyAdmin() view returns (address)"
    ) >= 0;

  const isAccessControl = (deployment: Deployment) =>
    deployment.abi.findIndex(
      (abi: any) =>
        abi.name === "getRoleMemberCount" ||
        abi === "function getRoleMember(bytes32,uint256) view returns (address)"
    ) >= 0;

  for (let i = 0; i < deploymentNames.length; i++) {
    const name = deploymentNames[i];
    const d = deployments[name];

    if (!isOwnable(d) && !isProxy(d) && !isAccessControl(d)) continue;

    console.log(`\x1b[0mchecking ownership for ${blue(name)}.`);

    console.log(
      `  Ownable: ${boolVal(isOwnable(d))}, Proxy: ${boolVal(
        isProxy(d)
      )}, AccessControl: ${boolVal(isAccessControl(d))}\x1b[90m`
    );

    if (isOwnable(d)) {
      const inst = await hre.ethers.getContractAt("Ownable", d.address);
      const owner = await inst.owner();

      if (owner.toLowerCase() != safe.toLowerCase()) {
        console.warn(`   WARN!! owner for ${name} is`, owner);
      } else {
        console.log(`owner for ${name} is`, owner);
      }
    }

    if (isProxy(d)) {
      const inst = await hre.ethers.getContractAt("MAHAProxy", d.address);
      const owner = await inst.proxyAdmin();
      if (owner.toLowerCase() != proxyAdmin.address.toLowerCase()) {
        console.warn(`   WARN!! proxyAdmin for ${name} is`, owner);
      }
    }

    if (isAccessControl(d)) {
      const inst = await hre.ethers.getContractAt(
        "AccessControlEnumerableUpgradeable",
        d.address
      );

      for (let j = 0; j < roles.length; j++) {
        await _checkRole(
          inst,
          name,
          roles[j],
          deployer.address,
          await hre.ethers.solidityPackedKeccak256(["string"], [roles[j]])
        );
      }

      await _checkRole(
        inst,
        name,
        "DEFAULT_ADMIN",
        deployer.address,
        await inst.DEFAULT_ADMIN_ROLE()
      );
    }
  }
});

const _checkRole = async (
  inst: AccessControlEnumerableUpgradeable,
  name: string,
  roleName: string,
  deployer: string,
  role: string
) => {
  const admins = await _getRoles(inst, role);
  if (admins.length == 0) return;

  console.log(`  checking ${roleName} roles for ${name}`);
  for (let i = 0; i < admins.length; i++) {
    console.log(`    user ${i + 1} is`, admins[i]);
    if (admins[i] == deployer.toLowerCase()) {
      console.warn(`   WARN!! deployer is ${roleName} for ${name}`);
    }
  }
};

const _getRoles = async (
  inst: AccessControlEnumerableUpgradeable,
  role: string
) => {
  const admins: string[] = [];
  const count = await inst.getRoleMemberCount(role);
  for (let i = 0; i < count; i++) {
    const members = await inst.getRoleMember(role, i);
    admins.push(members.toLowerCase());
  }
  return admins;
};
