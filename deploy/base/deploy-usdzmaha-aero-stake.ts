import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy, waitForTx } from "../../scripts/utils";
import { MaxUint256, ZeroAddress } from "ethers";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const mahaD = await deployments.get("MAHA");
  const usdcD = await deployments.get("USDC");
  const safe = "0x7427E82f5abCbcA2a45cAfE6e65cBC1FADf9ad9D";

  const name = "Staked xUSDz/MAHA Pool"; // string memory _name,
  const symbol = "sUSDZMAHA"; // string memory _symbol,
  const stakingToken = "0x6B22E989E1D74621ac4c8bcb62bcC7EE7c25b45A";

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

  const contractD = await deployProxy(
    hre,
    "StakingLPRewards",
    params,
    proxyAdminD.address,
    `StakingLPRewards-${symbol}`
  );

  const lp = await hre.ethers.getContractAt("StakingLPRewards", stakingToken);
  const contract = await hre.ethers.getContractAt(
    "StakingLPRewards",
    contractD.address
  );

  await waitForTx(await lp.approve(contract.target, MaxUint256));
  await waitForTx(await contract.mint(1000, safe));
}

main.tags = ["StakingLPRewards-Aero-sUSDZMAHA"];
export default main;
