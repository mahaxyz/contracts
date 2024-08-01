import { network } from "hardhat";
import { get } from "../guess/_helpers";
import { executeCreate2Proxy } from "./helpers";
import assert from "assert";

async function main() {
  assert(network.name !== "mainnet", "should not be mainnet");

  const implArgs = [
    "ZAI Stablecoin",
    "USDz",
    "0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b", // admin
  ];

  await executeCreate2Proxy(
    "ZaiStablecoin",
    "xZAI-Proxy",
    "XERC20",
    implArgs,
    get("XERC20-impl", "arbitrum"),
    "arbitrum",
    "0xd04a1c3fd1157d54d9d9d44577258e3d7bca482415a100e296b352dc71699259",
    "0x69000ee306393ef6f9a2a57d5cb5960263bd531f"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
