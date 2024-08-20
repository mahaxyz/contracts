import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const [deployer] = await hre.ethers.getSigners();
  const proxyAdminD = await deployments.get("ProxyAdmin");
  const zaiD = await deployments.get("ZaiStablecoin");
  const safe = "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC";

  const name = "Staked ZAI/FRAXBP Pool"; // string memory _name,
  const implArgs = [
    "sZAIFRAXBP", // string memory _symbol,
    "0x057c658dfbbcbb96c361fb4e66b86cca081b6c6a", // address _stakingToken,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _governance,
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _rewardToken1,
    "0x745407c86df8db893011912d3ab28e68b62e49b0", // address _rewardToken2,
    86400 * 7, // uint256 _rewardsDuration,
    ZeroAddress, // address _staking
  ];

  const params = [
    safe, // address _feeCollector,
    100000n * 10n ** 18n, // uint256 _globalDebtCeiling,
    zaiD.address, // address _zai,
    deployer.address, // address _governance
  ];

  await deployProxy(
    hre,
    "StakingLPRewards",
    params,
    proxyAdminD.address,
    `DDHub`
  );
}

main.tags = ["DeployDDHub"];
export default main;
