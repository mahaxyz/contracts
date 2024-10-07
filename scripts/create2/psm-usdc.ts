import { network } from "hardhat";
import { get } from "../guess/_helpers";
import { executeCreate2Proxy } from "./helpers";
import assert from "assert";

async function main() {
  assert(network.name === "mainnet", "not mainnet");

  const implArgs: any[] = [
    "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0", // address _zai,
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _collateral,
    "0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b", // address _governance,
    1e6, // uint256 _newRate,
    100000000n * 10n ** 6n, // uint256 _supplyCap,
    100000000n * 10n ** 18n, // uint256 _debtCap,
    0, // uint256 _mintFeeBps,
    300, // uint256 _redeemFeeBps,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _feeDestination
  ];

  await executeCreate2Proxy(
    "PegStabilityModule-USDC",
    "PegStabilityModule-USDC-Proxy",
    "PegStabilityModule",
    implArgs,
    get("PegStabilityModule-impl", "mainnet"),
    "mainnet",
    "0x7d6b5946c8a05e39fba146ac3459084bd594027a89980c3d197347cd7140cfad",
    "0x69000052a82e218ccb61fe6e9d7e3f87b9c5916f"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
