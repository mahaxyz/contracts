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
    get("XERC20-impl", network.name),
    "arbitrum",
    "0x07f7b4a675919f14b4ac361f5bbd083b8493fd1b3d43b957013f2eb971273abc",
    "0x69000cc63be9b4322f3f62c233dd1a7f509ae080"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
