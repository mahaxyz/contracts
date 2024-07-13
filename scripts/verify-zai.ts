import hre from "hardhat";

import contractArtifact from "../artifacts/contracts/core/ZaiStablecoin.sol/ZaiStablecoin.json";

async function main() {
  const constructorArguments = [
    "0x1a44076050125825900e736c501f859c50fE728c",
    "0xe5159e75ba5f1C9E386A3ad2FC7eA75c14629572",
  ];

  const address = "";

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
