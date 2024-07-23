import hre from "hardhat";

import contractArtifact from "../artifacts/contracts/core/ZaiStablecoin.sol/ZaiStablecoin.json";

async function main() {
  const constructorArguments = [];

  const address = "0x69000bb053EA517D72Bd401c6Bc561Fa8b1D00c7";

  hre.deployments.save("ZaiStablecoin", {
    address: address,
    args: constructorArguments,
    abi: contractArtifact.abi,
  });

  hre.run("verify:verify", {
    address: address,
    constructorArguments,
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
