import hre from "hardhat";

import Deployer from "../deployments/mainnet/Deployer.json";

async function main() {
  const { deployments } = hre;

  const [deployer] = await hre.ethers.getSigners();
  const factory = new hre.ethers.ContractFactory(
    Deployer.abi,
    Deployer.bytecode
  );
  const contract = await factory.connect(deployer).deploy();

  console.log(contract.target);
  console.log(await contract.deploymentTransaction());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
