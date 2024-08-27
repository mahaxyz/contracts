import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../../scripts/utils";
import { ZeroAddress } from "ethers";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const mahaD = await deployments.get("MAHA");
  const usdcD = await deployments.get("USDC");
  const safe = "0x7427E82f5abCbcA2a45cAfE6e65cBC1FADf9ad9D";

  const name = "Staked USDz/MAHA Pool"; // string memory _name,
  const symbol = "sUSDZMAHA"; // string memory _symbol,
  const stakingToken = "0x2b58eb0a363b023d1840ff1a69fb5c9170172e1e";

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

main.tags = ["StakingLPRewards-Aero-sUSDZMAHA"];
export default main;
