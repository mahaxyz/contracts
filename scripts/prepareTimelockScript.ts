import { keccak256 } from "ethers";
import { ethers, network, deployments } from "hardhat";

async function main() {
  console.log(`Deploying to ${network.name}...`);

  // const [deployer] = await ethers.getSigners();
  const deployer = await ethers.getSigner(
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC"
  );
  console.log(`Deployer address is ${deployer.address}.`);

  const timelockD = await deployments.get("MAHATimelockController");

  const timelock = await ethers.getContractAt(
    "MAHATimelockController",
    timelockD.address
  );

  const predecessor =
    "0x0000000000000000000000000000000000000000000000000000000000000000";
  const salt = ethers.id("task1");

  const contractD = await deployments.get("L2DepositCollateralL0");
  const contract = await ethers.getContractAt(
    "L2DepositCollateralL0",
    contractD.address
  );

  const data1 = await contract.setAllowedBridgeSweeper.populateTransaction(
    "0x24fF4165F1bc1621E23eFE9437ba8Bef8AC03D2A",
    true
  );

  console.log(data1);

  const schedule = await timelock.schedule.populateTransaction(
    data1.to,
    0,
    data1.data,
    predecessor, // bytes32 predecessor,
    salt, // bytes32 salt,
    3600
  );
  console.log("schedule tx", schedule);

  const execute = await timelock.execute.populateTransaction(
    data1.to,
    0,
    data1.data,
    predecessor, // bytes32 predecessor,
    salt // bytes32 salt,
  );
  console.log("execute tx", execute);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
