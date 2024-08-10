import { task } from "hardhat/config";
// import { waitForTx } from "../../scripts/utils";
// import { config } from "./config";
import assert from "assert";
import { AccessControlEnumerableUpgradeable } from "../../types";
import { Deployment } from "hardhat-deploy/dist/types";

task(
  `audit-ownerships`,
  `Checks if the protocol contracts are owned by the right addresses`
).setAction(async (_, hre) => {
  const deployments = await hre.deployments.all();
  const [deployer] = await hre.ethers.getSigners();

  const deploymentNames = Object.keys(deployments);
  const proxyAdmin = await hre.deployments.get("ProxyAdmin");

  for (let i = 0; i < deploymentNames.length; i++) {
    const name = deploymentNames[i];
    const deployment = deployments[name];

    if (deployment.abi.find((abi: any) => abi.name === "owner")) {
      const inst = await hre.ethers.getContractAt(
        "Ownable",
        deployment.address
      );
      const owner = await inst.owner();

      if (owner.toLowerCase() == deployer.address.toLowerCase()) {
        console.warn(`WARN!! owner at ${inst.target} for ${name} is`, owner);
      } else {
        console.log(`owner at ${inst.target} for ${name} is`, owner);
      }
    }

    if (deployment.abi.find((abi: any) => abi.name === "proxyAdmin")) {
      const inst = await hre.ethers.getContractAt(
        "MAHAProxy",
        deployment.address
      );
      const owner = await inst.proxyAdmin();
      if (owner.toLowerCase() != proxyAdmin.address.toLowerCase()) {
        console.warn(
          `WARN!! proxyAdmin at ${inst.target} for ${name} is`,
          owner
        );
      } else {
        console.log(`proxyAdmin at ${inst.target} for ${name} is`, owner);
      }
    }

    if (deployment.abi.find((abi: any) => abi.name === "getRoleMemberCount")) {
      const inst = await hre.ethers.getContractAt(
        "AccessControlEnumerableUpgradeable",
        deployment.address
      );

      _checkRole(
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

  console.log(`printing ${roleName} roles for ${name}`);
  for (let i = 0; i < admins.length; i++) {
    console.log(`   user ${i + 1} is`, admins[i]);
    if (admins[i] == deployer.toLowerCase()) {
      console.warn(
        `   WARN!! deployer is an admin at ${inst.target} for ${name}`
      );
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
