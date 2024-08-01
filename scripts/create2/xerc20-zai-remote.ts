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
    "0x52e810aa739c078a8b372f3e003efabc56ca497a06da279dbbc060bed8345146",
    "0xf1adca6863abe2fa5592c7220e5053b42a94e298"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
