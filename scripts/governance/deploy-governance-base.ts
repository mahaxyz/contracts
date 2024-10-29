import { ZeroAddress } from "ethers";
import { ethers, network, run } from "hardhat";

async function main() {
  const SAFE = "0x7427E82f5abCbcA2a45cAfE6e65cBC1FADf9ad9D";
  const MAHA_BASE = "0x554bba833518793056CF105E66aBEA330672c0dE";
  const WETH_BASE = "0x4200000000000000000000000000000000000006";
  const REWARD_DURATION = 86400 * 7; // 7 Days

  const TransparentProxy = await ethers.getContractFactory(
    "TransparentUpgradeableProxy"
  );
  const LockerToken = await ethers.getContractFactory("LockerToken");
  const OmnichainStakingToken = await ethers.getContractFactory(
    "OmnichainStakingToken"
  );

  // Deploy the implementations
  const omnichainStakingTokenImpl = await OmnichainStakingToken.deploy();
  const lockerTokenImpl = await LockerToken.deploy();

  await omnichainStakingTokenImpl.waitForDeployment();
  await lockerTokenImpl.waitForDeployment();

  console.log(
    `Omnichain Staking Implementation: ${await omnichainStakingTokenImpl.getAddress()}`
  );
  console.log(
    `Locker Token Implementation: ${await lockerTokenImpl.getAddress()}`
  );

  // Deploy proxies
  const omnichainStakingTokenProxy = await TransparentProxy.deploy(
    await omnichainStakingTokenImpl.getAddress(),
    SAFE,
    "0x"
  );
  const lockerTokenProxy = await TransparentProxy.deploy(
    await lockerTokenImpl.getAddress(),
    SAFE,
    "0x"
  );

  await omnichainStakingTokenProxy.waitForDeployment();
  await lockerTokenProxy.waitForDeployment();

  console.log(
    `Omnichain Staking Proxy: ${await omnichainStakingTokenProxy.getAddress()}`
  );
  console.log(`Locker Token Proxy: ${await lockerTokenProxy.getAddress()}`);

  // Interacting through proxies
  const omnichainStakingToken = await ethers.getContractAt(
    "OmnichainStakingToken",
    await omnichainStakingTokenProxy.getAddress()
  );

  const lockerToken = await ethers.getContractAt(
    "LockerToken",
    await lockerTokenProxy.getAddress()
  );

  // Initialize the contracts
  await lockerToken.init(
    MAHA_BASE,
    await omnichainStakingToken.getAddress(),
    ZeroAddress
  );

  await omnichainStakingToken.init(
    await lockerToken.getAddress(),
    WETH_BASE,
    MAHA_BASE,
    REWARD_DURATION,
    SAFE,
    ZeroAddress
  );

  if (network.name !== "hardhat") {
    // Verify the implementations
    await run("verify:verify", { address: await lockerTokenImpl.getAddress() });
    await run("verify:verify", {
      address: await omnichainStakingTokenImpl.getAddress(),
    });

    // Verify the proxies
    await run("verify:verify", {
      address: await lockerTokenProxy.getAddress(),
      constructorArguments: [await lockerTokenImpl.getAddress(), SAFE, "0x"],
    });
    await run("verify:verify", {
      address: await omnichainStakingTokenProxy.getAddress(),
      constructorArguments: [
        await omnichainStakingTokenImpl.getAddress(),
        SAFE,
        "0x",
      ],
    });
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
