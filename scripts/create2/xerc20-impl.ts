import hre from "hardhat";
import { executeCreate2 } from "./helpers";

async function main() {
  await executeCreate2(
    "XERC20-impl",
    "XERC20",
    [],
    hre.network.name,
    "0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d",
    "0x878df2f50de7077a0fe45f9e06253b7a591d22aa"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
