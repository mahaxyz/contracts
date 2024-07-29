import hre from "hardhat";

import contractArtifact from "../../artifacts/contracts/core/ZaiStablecoin.sol/ZaiStablecoin.json";

async function main() {
  const constructorArguments = ["0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b"];

  const address = "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0";

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
