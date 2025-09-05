import hre from "hardhat";
import { ethers } from "hardhat";
import { deployProxy, waitForTx } from "../utils";

async function main() {
    const [deployer] = await ethers.getSigners();
    const proxyAdminD = await hre.deployments.get("ProxyAdmin");
    const mahaD = await hre.deployments.get("MAHA");
    const wethD = await hre.deployments.get("WETH");
    const REWARD_DURATION = 86400 * 7; // 7 Days

    const lockerTokenProxyD = await deployProxy(
        hre,
        "LockerToken",
        [],
        proxyAdminD.address,
        "LockerToken-V3",
        deployer.address,
        true
      );
    
      // Deploy proxies
      const omnichainStakingTokenProxyD = await deployProxy(
        hre,
        "OmnichainStakingToken",
        [],
        proxyAdminD.address,
        "OmnichainStakingToken-V3",
        deployer.address,
        true
      );
    
      const lockerToken = await hre.ethers.getContractAt(
        "LockerToken",
        lockerTokenProxyD.address
      );
    
      const omnichainStakingToken = await hre.ethers.getContractAt(
        "OmnichainStakingToken",
        omnichainStakingTokenProxyD.address
      );

    // Initialize the contracts
    await waitForTx(
        await lockerToken.initialize(mahaD.address, omnichainStakingToken.target)
    );
    await waitForTx(
        await omnichainStakingToken.initialize(
            lockerToken.target,
            wethD.address,
            [mahaD.address, wethD.address],
            REWARD_DURATION,
            deployer.address, // owner
            deployer.address // distributor
        )
    );
}

main().catch((err) => {
    console.error(err);
    process.exitCode = 1;
});
