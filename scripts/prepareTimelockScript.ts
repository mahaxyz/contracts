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

  console.log({
    predecessor,
    salt,
  });

  const contractD = await deployments.get("DDHub");
  const contract = await ethers.getContractAt("DDHubL1", contractD.address);

  const hubD = await deployments.get("DDLayerZeroHub-Base-LZ");
  const planD = await deployments.get("DDOperatorPlan-Base-LZ");
  const cap = 10000000n * 10n ** 18n;

  const data = await contract.registerPool.populateTransaction(
    hubD.address,
    planD.address,
    cap
  );

  const executeTx = await timelock.schedule.populateTransaction(
    data.to, // address target, arth
    0, // uint256 value
    data.data, // bytes calldata data, toggleTroveManager
    predecessor, // bytes32 predecessor,
    salt, // bytes32 salt,
    3600
  );
  console.log(executeTx);

  // const arth = await ethers.getContractAt("ARTHValuecoin", execute[0]);
  // console.log(
  //   "tm address",
  //   await arth.troveManagerAddresses(
  //     "0xaefb39d1bc9f5f506730005ec96ff10b4ded8dda"
  //   )
  // );

  // console.log(`creating timelock tx...`);
  // const hash = await timelock.hashOperation(
  //   execute[0],
  //   execute[1],
  //   execute[2],
  //   execute[3],
  //   execute[4]
  // );
  // console.log(hash);

  // const tx = await timelock.connect(deployer).schedule(
  //   execute[0],
  //   execute[1],
  //   execute[2],
  //   execute[3],
  //   execute[4],
  //   await timelock.getMinDelay() // uint256 delay
  // );
  // console.log(`tx ${tx.hash}`);

  // console.log("is pending?", await timelock.isOperationPending(hash));
  // console.log("is done?", await timelock.isOperationDone(hash));
  // console.log("is ready?", await timelock.isOperationReady(hash));

  // // wait for 12 days
  // // suppose the current block has a timestamp of 01:00 PM
  // await network.provider.send("evm_setNextBlockTimestamp", [
  //   Math.floor(new Date("2023-09-01T00:00:00.000Z").getTime() / 1000),
  // ]);
  // await network.provider.send("evm_mine"); // this one will have 02:00 PM as its timestamp

  // console.log("is pending?", await timelock.isOperationPending(hash));
  // console.log("is done?", await timelock.isOperationDone(hash));
  // console.log("is ready?", await timelock.isOperationReady(hash));

  // // execute the tx
  // const tx2 = await timelock
  //   .connect(deployer)
  //   .execute(execute[0], execute[1], execute[2], execute[3], execute[4]);
  // console.log(`tx2 ${tx2.hash}`);

  // // now check whatever we want here
  // console.log(
  //   "tm address",
  //   await arth.troveManagerAddresses(
  //     "0xaefb39d1bc9f5f506730005ec96ff10b4ded8dda"
  //   )
  // );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
