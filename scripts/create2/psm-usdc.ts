import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";

async function main() {
  const factory = await hre.ethers.getContractFactory("MAHAProxy");
  const impl = await hre.ethers.getContractFactory("PegStabilityModule");

  const implArgs = [
    "0x6900057428C99Fb373397D657Beb40D92D8aC97f", // address _zai,
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _collateral,
    "0xe5159e75ba5f1C9E386A3ad2FC7eA75c14629572", // address _governance,
    1e6, // uint256 _newRate,
    10000000n * 10n ** 6n, // uint256 _supplyCap,
    10000000n * 10n ** 18n, // uint256 _debtCap,
    0, // uint256 _mintFeeBps,
    300, // uint256 _redeemFeeBps,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _feeDestination
  ];

  const initData = impl.interface.encodeFunctionData("initialize", implArgs);

  const constructorArgs: any[] = [
    "0x401139484880aD01Db2E75cA11d26FD7045e13f4",
    "0x69000f2f879ee598ddf16c6c33cfc4f2d983b6bd",
    initData,
  ];
  const salt =
    "0x471a78fa81e1c16f74411acf0ca44ca98b2257604cc0ae51c54cbd9f939131c8";
  const address = "0x69000a93c8acf8126d6ef5b1054c2695744ca4ee";

  const [wallet] = await hre.ethers.getSigners();
  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0xc07c1980C87bfD5de0DC77f90Ce6508c1C0795C3"
  );

  const bytecode = buildBytecode(
    ["address", "address", "bytes"],
    constructorArgs,
    factory.bytecode
  );

  const txPopulated = await deployer.deploy.populateTransaction(
    bytecode,
    ethers.id(salt)
  );
  const tx = await wallet.sendTransaction(txPopulated);

  const txR = await tx.wait(1);
  console.log(txR?.logs);

  if (network.name !== "hardhat") {
    await hre.deployments.save("PegStabilityModule-USDC", {
      address: address,
      args: implArgs,
      abi: impl.interface.format(true),
    });

    await hre.deployments.save("PegStabilityModule-USDC-Proxy", {
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
