import hre from "hardhat";
import { executeCreate2 } from "./helpers";

async function main() {
  await executeCreate2(
    "XERC20-impl",
    "XERC20",
    [],
    hre.network.name,
    "0x45dd06119cc192324da27568c18ebf284036bfebf10402b1cd4e1b2eb63402d4",
    "0x69000b9e02fd541c6e1df00470e12e968d419051"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
