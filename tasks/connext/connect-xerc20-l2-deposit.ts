import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import assert from "assert";

task(`connect-xerc20-l2-deposit`, `Connects the xerc20 to the deposit contract`)
  .addParam("limit", "limit of minting/burning")
  .setAction(async (params, hre) => {
    const xerc20D = await hre.deployments.get("xZAI-Proxy");
    const L2DepositCollateralConnextD = await hre.deployments.get(
      "L2DepositCollateralConnext"
    );

    const e18 = 10n ** 18n;
    const xerc20 = await hre.ethers.getContractAt("XERC20", xerc20D.address);

    const conifgLocal = config[hre.network.name];
    assert(!!conifgLocal, `Config not found for ${hre.network.name}`);

    const limit = params.limit === "" ? 0 : parseInt(params.limit);
    const limitE18 = BigInt(limit) * e18;

    console.log(`Setting limits for xERC20 - ${xerc20.target}`);
    console.log(
      `Setting limits for L2DepositCollateralConnext at ${L2DepositCollateralConnextD.address} to ${limitE18}`
    );
    await waitForTx(
      await xerc20.setLimits(
        L2DepositCollateralConnextD.address,
        limitE18,
        limitE18
      )
    );
  });
