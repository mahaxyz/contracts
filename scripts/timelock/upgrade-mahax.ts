import hre, { ethers, deployments } from "hardhat";
import { deployContract } from "../utils";
import { ZeroAddress } from "ethers";

async function main() {
  console.log(`preparing timelock data`);

  const deployer = await ethers.getSigner(
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC"
  );
  console.log(`Deployer address is ${deployer.address}.`);

  const newImpl = await deployContract(
    hre,
    "OmnichainStakingToken",
    [],
    "OmnichainStakingToken-v2"
  );

  const staking = await ethers.getContractAt(
    "OmnichainStakingToken",
    newImpl.address
  );

  const omnichainStakingToken = await deployments.get("OmnichainStakingToken");
  const lockerToken = await deployments.get("LockerToken");
  const wethD = await deployments.get("WETH");

  const initData = await staking.initialize.populateTransaction(
    lockerToken.address,
    wethD.address,
    [],
    1683216000,
    deployer.address,
    ZeroAddress
  );

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const proxyAdmin = await ethers.getContractAt(
    "ProxyAdmin",
    proxyAdminD.address
  );

  const upgradeTx = await proxyAdmin.upgradeAndCall.populateTransaction(
    omnichainStakingToken.address,
    newImpl.address,
    initData.data
  );

  console.log("initData", initData);
  console.log("upgradeTx", upgradeTx);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
