import { MaxUint256 } from "ethers";
import { network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

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

  const usdcPSM = await hre.ethers.getContractAt(
    "PegStabilityModule",
    usdcPSMD.address
  );

  const daiPSM = await hre.ethers.getContractAt(
    "PegStabilityModule",
    daiPSMD.address
  );

  const zai = await hre.ethers.getContractAt("ZaiStablecoin", zaiD.address);
  const usdc = await hre.ethers.getContractAt("MockERC20", mockUSDCD.address);
  const dai = await hre.ethers.getContractAt("MockERC20", mockDAID.address);

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
  );

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
  );

  await zai.grantManagerRole(daiPSM.target);
  await zai.grantManagerRole(usdcPSM.target);

  await usdc.mint(deployer, k100 * e6);
  await dai.mint(deployer, k100 * e18);

  await usdc.approve(usdcPSM.target, MaxUint256);
  await dai.approve(daiPSM.target, MaxUint256);
  await zai.approve(usdcPSM.target, MaxUint256);
  await zai.approve(daiPSM.target, MaxUint256);

  await usdcPSM.mint(deployer, 1000n * e18);
  await daiPSM.mint(deployer, 1000n * e18);

  await usdcPSM.redeem(deployer, 100n * e18);
  await daiPSM.redeem(deployer, 100n * e18);

  if (network.name !== "hardhat") {
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
