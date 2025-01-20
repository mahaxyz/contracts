import hre from "hardhat";
import { ZeroAddress } from "ethers";
import { ethers, network, run } from "hardhat";
import { deployContract, waitForTx } from "../utils";

async function main() {
  const SAFE = "0x7427E82f5abCbcA2a45cAfE6e65cBC1FADf9ad9D";
  const MAHA_BASE = "0x554bba833518793056CF105E66aBEA330672c0dE";
  const WETH_BASE = "0x4200000000000000000000000000000000000006";
  const REWARD_DURATION = 86400 * 7; // 7 Days

  const [deployer] = await ethers.getSigners();

  const proxyAdminD = await hre.deployments.get("ProxyAdmin");

  // Deploy the implementations
  const omnichainStakingTokenImpl = await deployContract(
    hre,
    "OmnichainStakingToken",
    [],
    "OmnichainStakingTokenImpl"
  );
  const lockerTokenImpl = await deployContract(
    hre,
    "LockerToken",
    [],
    "LockerTokenImpl"
  );

  // Deploy proxies
  const omnichainStakingTokenProxyD = await deployContract(
    hre,
    "TransparentUpgradeableProxy",
    [omnichainStakingTokenImpl.address, proxyAdminD.address, "0x"],
    "OmnichainStakingToken"
  );
  const lockerTokenProxyD = await deployContract(
    hre,
    "TransparentUpgradeableProxy",
    [lockerTokenImpl.address, proxyAdminD.address, "0x"],
    "LockerToken"
  );

  const omnichainStakingToken = await hre.ethers.getContractAt(
    "OmnichainStakingToken",
    omnichainStakingTokenProxyD.address
  );
  const lockerToken = await hre.ethers.getContractAt(
    "LockerToken",
    lockerTokenProxyD.address
  );

  // Initialize the contracts
  await waitForTx(
    await lockerToken.initialize(MAHA_BASE, omnichainStakingToken.target)
  );
  await waitForTx(
    await omnichainStakingToken.initialize(
      lockerToken.target,
      WETH_BASE,
      [MAHA_BASE, WETH_BASE],
      REWARD_DURATION,
      deployer.address,
      ZeroAddress
    )
  );
  await waitForTx(await omnichainStakingToken.setMigrator(deployer.address));
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
