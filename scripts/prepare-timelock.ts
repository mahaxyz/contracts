import { Addressable, ContractTransaction } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export const getTimelock = async (
  hre: HardhatRuntimeEnvironment,
  address?: string | Addressable
) => {
  if (!address)
    address = (await hre.deployments.get("MAHATimelockController")).address;
  return await hre.ethers.getContractAt("MAHATimelockController", address);
};

export const prepareTimelockData = async (
  hre: HardhatRuntimeEnvironment,
  from: string | Addressable,
  txs: ContractTransaction[] = [],
  timelockAddr?: string | Addressable
) => {
  const timelock = await getTimelock(hre, timelockAddr);

  const salt = hre.ethers.id("salt");
  const predecessor = hre.ethers.zeroPadValue("0x00", 32);
  console.log("using salt", salt);
  console.log("using predecessor", predecessor);

  const minDelay = await timelock.getMinDelay();
  console.log("minDelay", minDelay);

  const schedule = await timelock.scheduleBatch.populateTransaction(
    txs.map((tx) => tx.to),
    txs.map(() => 0),
    txs.map((tx) => tx.data),
    predecessor,
    salt,
    minDelay
  );
  const execute = await timelock.executeBatch.populateTransaction(
    txs.map((tx) => tx.to),
    txs.map(() => 0),
    txs.map((tx) => tx.data),
    predecessor,
    salt
  );

  console.log("");
  console.log("from", from);
  console.log("to", schedule.to);
  console.log("\nschedule tx");
  console.log(schedule.data);
  console.log("\nexecute tx");
  console.log(execute.data);
  console.log("");

  return { schedule, execute };
};
