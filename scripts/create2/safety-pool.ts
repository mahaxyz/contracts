import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";
import { ZeroAddress } from "ethers";

async function main() {
  const factory = await hre.ethers.getContractFactory("MAHAProxy");
  const impl = await hre.ethers.getContractFactory("SafetyPool");

  const implArgs = [
    "Staked ZAI Stablecoin", // string memory _name,
    "sUSDz", // string memory _symbol,
    "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0", // address _stablecoin,
    86400 * 10, // uint256 _withdrawalDelay,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _governance,
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _rewardToken1,
    "0x745407c86df8db893011912d3ab28e68b62e49b0", // address _rewardToken2,
    86400 * 7, // uint256 _rewardsDuration,
    ZeroAddress, // address _stakingBoost
  ];

  const initData = impl.interface.encodeFunctionData("initialize", implArgs);

  const constructorArgs: any[] = [
    "0xb6761274addfCF738344Ac4C6566AD5c0255Aaa0",
    "0x6900064e7a3920c114e25b5fe4780f26520e3231",
    initData,
  ];
  const salt =
    "0x25b1e7ea85ff6cd0b94443b4a4829e5a4f01ecaf3bd8257e2cd4e4fc9b54aba1";
  const target = "0x69000e468f7f6d6f4ed00cf46f368acdac252553";

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
    await hre.deployments.save("SafetyPool-USDz", {
      address: target,
      args: implArgs,
      abi: impl.interface.format(true),
    });

    await hre.deployments.save("SafetyPool-USDz-Proxy", {
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
