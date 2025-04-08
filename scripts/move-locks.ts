import { keccak256 } from "ethers";
import { ethers, network, deployments } from "hardhat";
import { waitForTx } from "./utils";

async function main() {
  console.log(`Deploying to ${network.name}...`);

  const [deployer] = await ethers.getSigners();
  console.log(`Deployer address is ${deployer.address}.`);
  // const deployer = await ethers.getSigner(
  //   "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC"
  // );

  const timelockD = await deployments.get("OmnichainStakingToken");

  const staking = await ethers.getContractAt(
    "OmnichainStakingToken",
    timelockD.address
  );

  await waitForTx(
    await staking.moveLockOwnership(
      "132",
      "0x7202136d70026DA33628dD3f3eFccb43F62a2469"
    )
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
