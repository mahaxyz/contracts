import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy, waitForTx } from "../../scripts/utils";
import { MaxUint256, ZeroAddress } from "ethers";

export async function deployLpStaking(
  hre: HardhatRuntimeEnvironment,
  name: string,
  symbol: string,
  lpD: string
) {
  const { deployments } = hre;

  const [deployer] = await hre.ethers.getSigners();
  const proxyAdminD = await deployments.get("ProxyAdmin");
  const mahaD = await deployments.get("MAHA");
  const zaiD = await deployments.get("ZaiStablecoinOFT");
  const safe = await deployments.get("GnosisSafe");
  const timelockD = await deployments.get("MAHATimelockController");

  const params = [
    name,
    symbol,
    lpD, // address _stakingToken,
    timelockD.address, // address _governance,
    zaiD.address, // address _rewardToken1,
    mahaD.address, // address _rewardToken2,
    86400 * 7, // uint256 _rewardsDuration,
    ZeroAddress, // address _staking
  ];

  const contractD = await deployProxy(
    hre,
    "StakingLPRewards",
    params,
    proxyAdminD.address,
    `StakingLPRewards-${symbol}`
  );

  const lp = await hre.ethers.getContractAt("StakingLPRewards", lpD);
  const contract = await hre.ethers.getContractAt(
    "StakingLPRewards",
    contractD.address
  );

  const balance = await lp.balanceOf(deployer.address);
  if (balance > 0n) {
    await waitForTx(await lp.approve(contract.target, MaxUint256));
    await waitForTx(await contract.mint(balance, safe.address));
  }
}
