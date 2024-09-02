import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy, waitForTx } from "../../scripts/utils";
import { MaxUint256 } from "ethers";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const mahaD = await deployments.get("MAHA");
  const usdcD = await deployments.get("USDC");
  const vault = await deployments.get("StakingLPRewards-sUSDZUSDC");
  const safe = "0x7427E82f5abCbcA2a45cAfE6e65cBC1FADf9ad9D";

  const name = "Wrapped Staked xUSDz/USDC Pool"; // string memory _name,
  const symbol = "wsUSDZUSDC"; // string memory _symbol,
  const stakingToken = "0x72d509aff75753aaad6a10d3eb98f2dbc58c480d";

  const params = [
    name, // string memory _name,
    symbol, // string memory _symbol,
    vault.address, // address _vault,
    [mahaD.address, usdcD.address], // address[] memory _rewardTokens
  ];

  const contractD = await deployProxy(
    hre,
    "WrappedStakingLPRewards",
    params,
    proxyAdminD.address,
    `WrappedStakingLPRewards-${symbol}`
  );

  const lp = await hre.ethers.getContractAt(
    "WrappedStakingLPRewards",
    stakingToken
  );
  const contract = await hre.ethers.getContractAt(
    "WrappedStakingLPRewards",
    contractD.address
  );

  // await waitForTx(await lp.approve(contract.target, MaxUint256));
  await waitForTx(
    await contract.deposit(1000, "0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b")
  );
}

main.tags = ["Wrapped-StakingLPRewards-Aero-sUSDZUSDC"];
export default main;
