import { ethers, deployments } from "hardhat";

async function main() {
  console.log(`preparing timelock data`);

  // set these values accordingly
  const hubD = await deployments.get("DDLayerZeroHub-Base-LZ");
  const planD = await deployments.get("DDOperatorPlan-Base-LZ");
  const cap = 1000000n * 10n ** 18n;

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

  console.log({
    predecessor,
    salt,
  });

  const contractD = await deployments.get("DDHub");
  const contract = await ethers.getContractAt("DDHubL1", contractD.address);

  const data1 = await contract.registerPool.populateTransaction(
    hubD.address,
    planD.address,
    cap
  );

  console.log("hub L1 destination", hubD.address);
  console.log("hub L1 plan", planD.address);
  console.log("hub L1 cap", cap);
  console.log("registerPool data", data1);

  const scheduleTx = await timelock.schedule.populateTransaction(
    data1.to,
    0, // uint256 value
    data1.data, // bytes calldata data, toggleTroveManager
    predecessor, // bytes32 predecessor,
    salt, // bytes32 salt,
    await timelock.getMinDelay() // 3600
  );
  console.log("scheduleTx data", scheduleTx);

  const executeTx = await timelock.execute.populateTransaction(
    data1.to,
    0, // uint256 value
    data1.data, // bytes calldata data, toggleTroveManager
    predecessor, // bytes32 predecessor,
    salt // bytes32 salt,
  );
  console.log("executeTx data", executeTx);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
