import hre from "hardhat";

import contractArtifact from "../../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json";

async function main() {
  await hre.deployments.save("USDC", {
    address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    abi: contractArtifact.abi,
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
