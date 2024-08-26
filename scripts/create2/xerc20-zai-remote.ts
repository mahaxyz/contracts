import { network } from "hardhat";
import { get } from "../guess/_helpers";
import { executeCreate2Proxy } from "./helpers";
import assert from "assert";

async function main() {
  assert(network.name !== "mainnet", "should not be mainnet");

  const implArgs = [
    "ZAI Stablecoin",
    "xUSDz",
    "0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b", // admin
  ];

  await executeCreate2Proxy(
    "ZaiStablecoin",
    "xZAI-Proxy",
    "XERC20",
    implArgs,
    get("XERC20-impl", network.name),
    network.name,
    "0x2fcf32741f80f7e50bab7728ed54fd9f51edf766b3dda12113c84096ffc2fae8",
    "0x69000a259d21c1824c7ffe3fd1e19a557a81d87e"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
