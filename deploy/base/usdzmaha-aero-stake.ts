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
  const vault = await deployments.get("StakingLPRewards-sUSDZUSDC");
  const safe = "0x7427E82f5abCbcA2a45cAfE6e65cBC1FADf9ad9D";

  const name = "Wrapped Staked xUSDz/MAHA Pool"; // string memory _name,
  const symbol = "wsUSDZMAHA"; // string memory _symbol,
  const stakingToken = "0x6B22E989E1D74621ac4c8bcb62bcC7EE7c25b45A";

  const params = [
    name, // string memory _name,
    symbol, // string memory _symbol,
    vault.address, // address _vault,
    [mahaD.address, usdcD.address], // address[] memory _rewardTokens
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
