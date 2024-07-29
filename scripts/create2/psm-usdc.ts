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
    "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0"
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

  const txR = await waitForTx(await wallet.sendTransaction(txPopulated));
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
