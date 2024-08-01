import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import assert from "assert";
import { MaxUint256 } from "ethers";

task(`test-restake`).setAction(async (_, hre) => {
  const conifgLocal = config[hre.network.name];
  assert(!!conifgLocal, `Config not found for ${hre.network.name}`);

  const contractD = await hre.deployments.get("L2DepositCollateral");

  const contract = await hre.ethers.getContractAt(
    "L2DepositCollateral",
    contractD.address
  );
  const erc20 = await hre.ethers.getContractAt("MockERC20", conifgLocal.usdc);

  console.log("deposit contract is at", contract.target);
  await waitForTx(await erc20.approve(contract.target, MaxUint256));
  await waitForTx(await contract.deposit(10e6, 0, Date.now()));
});
