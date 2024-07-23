import hre from "hardhat";

async function main() {
  const constructorArgs: any[] = [];
  const factory = await hre.ethers.getContractFactory("ZaiStablecoin");

  const tx = await factory.deploy(...constructorArgs);
  console.log(tx.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
