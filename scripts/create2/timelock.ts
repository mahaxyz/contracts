import { executeCreate2 } from "./helpers";

async function main() {
  const constructorArgs: any[] = [
    60 * 60,
    "0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b",
    ["0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b"],
  ];

  await executeCreate2(
    "MAHATimelockController",
    "MAHATimelockController",
    constructorArgs,
    "arbitrum",
    "0xe0bcdd4e23c1a527f2e76f1cf91d3065c17f0259fd17bdb4525ab0b04d735d91",
    "0x690005544ba364a53dcc9e8d81c9ce1e90018ab7"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
