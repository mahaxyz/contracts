import hre from "hardhat";
import { get } from "../guess/_helpers";
import { executeCreate2 } from "./helpers";

async function main() {
  const constructorArgs: any[] = [
    get("MAHATimelockController", hre.network.name),
  ];

  await executeCreate2(
    "ProxyAdmin",
    "ProxyAdmin",
    constructorArgs,
    hre.network.name,
    "0x86a0f351e764fdbad44e9da5c2796da3fbebddd97dba18ca9306b519fce81bfc",
    "0x69000c978701fc4427d4baf749f10a5cec582863"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
