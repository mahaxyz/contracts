import { ZeroAddress } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const safe = "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC";
  const usdcD = await deployments.get("USDC");
  const mahaD = await deployments.get("MAHA");

  const token = await hre.ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol:IERC20Metadata",
    "0x6ee1955afb64146b126162b4ff018db1eb8f08c3"
  );

  const name = await token.name();
  const symbol = await token.symbol();

  const params = [
    `Staked ${name}`, // string memory _name,
    `s${symbol}`, // string memory _symbol,
    token.target, // address _stakingToken,
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
    `StakingLPRewards-${params[1]}`
  );

  await deployments.save(`LP-Token-${symbol}`, {
    address: token.target.toString(),
    abi: token.interface.format(true),
  });
}

main.tags = ["DeployLpPool"];
export default main;
