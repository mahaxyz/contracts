import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";
import { ZeroAddress } from "ethers";

async function main() {
  const factory = await hre.ethers.getContractFactory("MAHAProxy");
  const impl = await hre.ethers.getContractAt(
    "StakingLPRewards",
    "0x0fDddA590cA26cfa5Cb974b4f3e3991D8348c677"
  );

  const implArgs = [
    "Staked ZAI/FRAXBP Pool", // string memory _name,
    "sZAIFRAXBP", // string memory _symbol,
    "0x057c658dfbbcbb96c361fb4e66b86cca081b6c6a", // address _stakingToken,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _governance,
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _rewardToken1,
    "0x745407c86df8db893011912d3ab28e68b62e49b0", // address _rewardToken2,
    86400 * 7, // uint256 _rewardsDuration,
    ZeroAddress, // address _staking
  ];

  const initData = impl.interface.encodeFunctionData("initialize", implArgs);

  const constructorArgs: any[] = [
    impl.target,
    "0x6900064e7a3920c114e25b5fe4780f26520e3231",
    initData,
  ];
  const salt =
    "0xd5f6ce2e8bdbc58dd3b7d5c92c852778ad2ade41e24a825f5e699b04bdcf68dd";
  const address = "0x6900066d9f8df0bfaf1e25ef89c0453e8e12373d";

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0"
  );

  const bytecode = buildBytecode(
    ["address", "address", "bytes"],
    constructorArgs,
    factory.bytecode
  );

  // await waitForTx(
  //   await deployer.deployWithAssert(bytecode, ethers.id(salt), address)
  // );

  if (network.name !== "hardhat") {
    await hre.deployments.save(`StakingLPRewards-${implArgs[1]}`, {
      address: address,
      args: implArgs,
      abi: impl.interface.format(true),
    });

    await hre.deployments.save(`StakingLPRewards-${implArgs[1]}-Proxy`, {
      address: address,
      args: constructorArgs,
      abi: factory.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: address,
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
