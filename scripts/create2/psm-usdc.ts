import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";

async function main() {
  const factory = await hre.ethers.getContractFactory("MAHAProxy");
  const impl = await hre.ethers.getContractFactory("PegStabilityModule");

  const implArgs = [
    "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0", // address _zai,
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _collateral,
    "0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b", // address _governance,
    1e6, // uint256 _newRate,
    10000000n * 10n ** 6n, // uint256 _supplyCap,
    10000000n * 10n ** 18n, // uint256 _debtCap,
    0, // uint256 _mintFeeBps,
    300, // uint256 _redeemFeeBps,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _feeDestination
  ];

  const initData = impl.interface.encodeFunctionData("initialize", implArgs);

  const constructorArgs: any[] = [
    "0x6A661312938D22A2A0e27F585073E4406903990a",
    "0x6900064e7a3920c114e25b5fe4780f26520e3231",
    initData,
  ];
  const salt =
    "0x7d6b5946c8a05e39fba146ac3459084bd594027a89980c3d197347cd7140cfad";
  const target = "0x69000052a82e218ccb61fe6e9d7e3f87b9c5916f";

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0"
  );

  const bytecode = buildBytecode(
    ["address", "address", "bytes"],
    constructorArgs,
    factory.bytecode
  );

  await waitForTx(
    await deployer.deployWithAssert(bytecode, ethers.id(salt), target)
  );

  if (network.name !== "hardhat") {
    await hre.deployments.save("PegStabilityModule-USDC", {
      address: target,
      args: implArgs,
      abi: impl.interface.format(true),
    });

    await hre.deployments.save("PegStabilityModule-USDC-Proxy", {
      address: target,
      args: constructorArgs,
      abi: factory.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: target,
      constructorArguments: constructorArgs,
    });
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
