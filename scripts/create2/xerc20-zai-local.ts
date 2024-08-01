import { network } from "hardhat";
import { get } from "../guess/_helpers";
import { executeCreate2Proxy } from "./helpers";
import assert from "assert";

async function main() {
  assert(network.name === "mainnet", "not mainnet");

  const implArgs = [
    "xZAI Stablecoin",
    "xUSDz",
    "0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b", // admin
  ];

  await executeCreate2Proxy(
    "xZAI-Stablecoin",
    "xZAI-Proxy",
    "XERC20",
    implArgs,
    get("XERC20-impl", "mainnet"),
    "mainnet",
    "0xfc44c6220e24c4d289f1c97b51df51573d769db1fa3fb2065f0ec3591eb962fd",
    "0x6900070de14fffaf3a129dc3880e0153444167fa"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
