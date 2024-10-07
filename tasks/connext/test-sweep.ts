import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import assert from "assert";

task(`test-sweep`).setAction(async (_, hre) => {
  const conifgLocal = config[hre.network.name];
  assert(!!conifgLocal, `Config not found for ${hre.network.name}`);

  const contractD = await hre.deployments.get("L2DepositCollateralConnext");

  const contract = await hre.ethers.getContractAt(
    "L2DepositCollateralConnext",
    contractD.address
  );

  console.log("deposit contract is at", contract.target);
  await waitForTx(await contract.sweep());
});
