import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy, waitForTx } from "../../scripts/utils";
import { MaxUint256, ZeroAddress } from "ethers";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "mainnet", "Wrong network");
  const { deployments } = hre;

  const [deployer] = await hre.ethers.getSigners();
  const proxyAdminD = await deployments.get("ProxyAdmin");
  const mahaD = await deployments.get("MAHA");
  const zaiD = await deployments.get("ZAI");
  const lpD = await deployments.get("LP-Token-ZAIUSDC");
  const safe = await deployments.get("GnosisSafe");
  const timelockD = await deployments.get("MAHATimelockController");

  const name = "Staked ZAI/USDC Pool"; // string memory _name,
  const symbol = "sZAIUSDC"; // string memory _symbol,

  const params = [
    name,
    symbol,
    lpD.address, // address _stakingToken,
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

  const lp = await hre.ethers.getContractAt("StakingLPRewards", lpD.address);
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

main.tags = ["StakingLPRewards-Curve-ZAI-USDC"];
export default main;
