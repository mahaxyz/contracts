import { ethers, deployments } from "hardhat";

async function main() {
  console.log(`preparing timelock data`);

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

  const data1 = await timelock.updateDelay.populateTransaction(86400 * 3);

  console.log("timelock delay", data1);
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
