import { MaxUint256, ZeroAddress } from "ethers";
import { network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { waitForTx } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const e6 = 10n ** 6n;
  const e18 = 10n ** 18n;
  const k100 = 100000n;

  const zaiD = await deploy("ZaiStablecoin", {
    from: deployer,
    contract: "ZaiStablecoin",
    args: [deployer],
    autoMine: true,
    log: true,
  });

  const mockUSDCD = await deploy("USDC", {
    from: deployer,
    contract: "MockERC20",
    args: ["USDC", "USDC", 6],
    autoMine: true,
    log: true,
  });

  const mockMAHAD = await deploy("MAHA", {
    from: deployer,
    contract: "MockERC20",
    args: ["MahaDAO", "MAHA", 18],
    autoMine: true,
    log: true,
  });

  const mockDAID = await deploy("DAI", {
    from: deployer,
    contract: "MockERC20",
    args: ["DAI", "DAI", 18],
    autoMine: true,
    log: true,
  });

  const usdcPSMD = await deploy("PegStabilityModule-USDC", {
    from: deployer,
    contract: "PegStabilityModule",
    args: [],
    autoMine: true,
    log: true,
  });

  const daiPSMD = await deploy("PegStabilityModule-DAI", {
    from: deployer,
    contract: "PegStabilityModule",
    args: [],
    autoMine: true,
    log: true,
  });

  const safetyPoolZaiD = await deploy("SafetyPool-ZAI", {
    from: deployer,
    contract: "SafetyPool",
    args: [],
    autoMine: true,
    log: true,
  });

  const zapSafetyPoolD = await deploy("ZapSafetyPool", {
    from: deployer,
    contract: "ZapSafetyPool",
    args: [safetyPoolZaiD.address, zaiD.address],
    autoMine: true,
    log: true,
  });

  const usdcPSM = await hre.ethers.getContractAt(
    "PegStabilityModule",
    usdcPSMD.address
  );

  const daiPSM = await hre.ethers.getContractAt(
    "PegStabilityModule",
    daiPSMD.address
  );
  const safetyPoolZai = await hre.ethers.getContractAt(
    "SafetyPool",
    safetyPoolZaiD.address
  );
  const zapSafetyPool = await hre.ethers.getContractAt(
    "ZapSafetyPool",
    zapSafetyPoolD.address
  );

  const zai = await hre.ethers.getContractAt("ZaiStablecoin", zaiD.address);
  const usdc = await hre.ethers.getContractAt("MockERC20", mockUSDCD.address);
  const dai = await hre.ethers.getContractAt("MockERC20", mockDAID.address);
  const maha = await hre.ethers.getContractAt("MockERC20", mockMAHAD.address);

  console.log("initializing contracts...");
  if ((await usdcPSM.zai()) !== zai.target)
    await waitForTx(
      await usdcPSM.initialize(
        zai.target, // address _zai,
        usdc.target, // address _collateral,
        deployer, // address _governance,
        e6, // uint256 _newRate,
        k100 * e6, // uint256 _supplyCap,
        k100 * e18, // uint256 _debtCap,
        0, // uint256 _mintFeeBps,
        100, // uint256 _redeemFeeBps,
        deployer // address _feeDestination
      )
    );

  if ((await daiPSM.zai()) !== zai.target)
    await waitForTx(
      await daiPSM.initialize(
        zai.target, // address _zai,
        dai.target, // address _collateral,
        deployer, // address _governance,
        e18, // uint256 _newRate,
        k100 * e18, // uint256 _supplyCap,
        k100 * e18, // uint256 _debtCap,
        0, // uint256 _mintFeeBps,
        100, // uint256 _redeemFeeBps,
        deployer // address _feeDestination
      )
    );

  if ((await safetyPoolZai.asset()) !== zai.target) {
    await waitForTx(
      await safetyPoolZai.initialize(
        "Staked ZAI", // string memory _name,
        "sUSDz", // string memory _symbol,
        zai.target, // address _stablecoin,
        600, // uint256 _withdrawalDelay,
        deployer, // address _governance,
        maha.target, // address _rewardToken1,
        usdc.target, // address _rewardToken2,
        86400, // uint256 _rewardsDuration
        ZeroAddress // address _stakingBoost
      )
    );
  }

  console.log("done, initializing contracts...");
  if (!zai.isManager(daiPSM.target))
    await waitForTx(await zai.grantManagerRole(daiPSM.target));
  if (!zai.isManager(usdcPSM.target))
    await waitForTx(await zai.grantManagerRole(usdcPSM.target));
  if (!zai.isManager(deployer))
    await waitForTx(await zai.grantManagerRole(deployer));
  if (!safetyPoolZai.hasRole(await safetyPoolZai.DISTRIBUTOR_ROLE(), deployer))
    await waitForTx(
      await safetyPoolZai.grantRole(
        await safetyPoolZai.DISTRIBUTOR_ROLE(),
        deployer
      )
    );

  console.log("minting tokens...");
  await waitForTx(await usdc.mint(deployer, k100 * e6));
  await waitForTx(await dai.mint(deployer, k100 * e18));
  await waitForTx(await zai.mint(deployer, k100 * e18));
  await waitForTx(await maha.mint(deployer, k100 * e18));

  console.log("giving approvals");
  await waitForTx(await dai.approve(daiPSM.target, MaxUint256));
  await waitForTx(await maha.approve(safetyPoolZai.target, MaxUint256));
  await waitForTx(await usdc.approve(safetyPoolZai.target, MaxUint256));
  await waitForTx(await usdc.approve(usdcPSM.target, MaxUint256));
  await waitForTx(await usdc.approve(zapSafetyPool.target, MaxUint256));
  await waitForTx(await zai.approve(daiPSM.target, MaxUint256));
  await waitForTx(await zai.approve(safetyPoolZai.target, MaxUint256));
  await waitForTx(await zai.approve(usdcPSM.target, MaxUint256));

  console.log("testing safety pool zap");
  await waitForTx(
    await zapSafetyPool.zapIntoSafetyPool(usdcPSM.target, 100n * e6)
  );

  console.log("testing psm mint");
  await waitForTx(await usdcPSM.mint(deployer, 1000n * e18));
  await waitForTx(await daiPSM.mint(deployer, 1000n * e18));

  console.log("testing psm redeem");
  await waitForTx(await usdcPSM.redeem(deployer, 100n * e18));
  await waitForTx(await daiPSM.redeem(deployer, 100n * e18));

  console.log("granting safety pool rewards");
  await waitForTx(
    await safetyPoolZai.notifyRewardAmount(maha.target, 100n * e18)
  );
  await waitForTx(
    await safetyPoolZai.notifyRewardAmount(usdc.target, 100n * e6)
  );

  console.log("testing safety pool");
  await waitForTx(await safetyPoolZai.mint(100n * e18, deployer));
  await waitForTx(await safetyPoolZai.queueWithdrawal(10n * e18));
  // await safetyPoolZai.redeem(10n * e18, deployer, deployer);

  console.log("testing safety pool zap");
  await waitForTx(
    await zapSafetyPool.zapIntoSafetyPool(usdcPSM.target, 100n * e6)
  );

  if (network.name !== "hardhat") {
    console.log("verifying contracts");
    await hre.run("verify:verify", {
      address: zapSafetyPool.target,
      constructorArguments: [safetyPoolZaiD.address, zaiD.address],
    });
    await hre.run("verify:verify", {
      address: zaiD.address,
      constructorArguments: [deployer],
    });
    await hre.run("verify:verify", {
      address: daiPSMD.address,
      constructorArguments: [],
    });
    await hre.run("verify:verify", {
      address: usdcPSMD.address,
      constructorArguments: [],
    });
    await hre.run("verify:verify", {
      address: safetyPoolZaiD.address,
      constructorArguments: [],
    });
    await hre.run("verify:verify", {
      address: mockDAID.address,
      constructorArguments: ["DAI", "DAI", 18],
    });
    await hre.run("verify:verify", {
      address: mockUSDCD.address,
      constructorArguments: ["USDC", "USDC", 8],
    });
  }
}

main.tags = ["testnet"];
export default main;
