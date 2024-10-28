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

  const omnichainStakingTokenImpl = await OmnichainStakingToken.deploy();
  const lockerTokenImpl = await LockerToken.deploy();

  await omnichainStakingTokenImpl.waitForDeployment();
  await lockerTokenImpl.waitForDeployment();


  console.log(
    `Omnichain Staking Implementation ${omnichainStakingTokenImpl.target}`
  );
  console.log(`Locker Token Implementation ${lockerTokenImpl.target}`);

  // Now proxies
  const OmnichainStakingTokenProxy = await TransparentProxy.deploy(
    omnichainStakingTokenImpl.target,
    SAFE,
    "0x"
  );
  const LockerTokenProxy = await TransparentProxy.deploy(
    lockerTokenImpl.target,
    SAFE,
    "0x"
  );

  const omnichainStakingToken = await ethers.getContractAt(
    "OmnichainStakingToken",
    OmnichainStakingTokenProxy.target
  );
  const lockerToken = await ethers.getContractAt(
    "LockerToken",
    LockerTokenProxy.target
  );

  // Initialize the contract
  await lockerToken.init(MAHA_BASE, omnichainStakingToken.target, ZeroAddress);
  await omnichainStakingToken.init(
    lockerToken.target,
    WETH_BASE,
    MAHA_BASE,
    REWARD_DURATION,
    SAFE,
    ZeroAddress
  );

  if (network.name !== "hardhat") {
    // Verify the implementation
    await run("verify:verify", { address: lockerTokenImpl.target });
    await run("verify:verify", { address: omnichainStakingTokenImpl.target });

    // Verify the proxy
    await run("verify:verify", {
      address: lockerToken.target,
      constructorArguments: [lockerTokenImpl.target, SAFE, "0x"],
    });

    await run("verify:verify", {
      address: omnichainStakingToken.target,
      constructorArguments: [omnichainStakingTokenImpl.target, SAFE, "0x"],
    });
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
