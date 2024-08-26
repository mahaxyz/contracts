import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../../scripts/utils";
import { ZeroAddress } from "ethers";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const mahaD = await deployments.get("MAHAOFT");
  const usdcD = await deployments.get("USDC");
  const safe = "0x7427E82f5abCbcA2a45cAfE6e65cBC1FADf9ad9D";

  const name = "Staked USDz/USDC Pool"; // string memory _name,
  const symbol = "sUSDZUSDC"; // string memory _symbol,
  const stakingToken = "0xd52881ea5880712a3f91bc1391598312321d2d84";

  const params = [
    name,
    symbol,
    stakingToken, // address _stakingToken,
    safe, // address _governance,
    usdcD.address, // address _rewardToken1,
    mahaD.address, // address _rewardToken2,
    86400 * 7, // uint256 _rewardsDuration,
    ZeroAddress, // address _staking
  ];

  await deployProxy(
    hre,
    "StakingLPRewards",
    params,
    proxyAdminD.address,
    `StakingLPRewards-${symbol}`
  );
}

main.tags = ["StakingLPRewards-Aero-sUSDZUSDC"];
export default main;
