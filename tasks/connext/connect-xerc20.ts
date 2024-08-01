import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import assert from "assert";

task(`connect-xerc20`, `Connects the xerc20 to the bridge`)
  .addParam("limit", "limit of minting/burning")
  .setAction(async (params, hre) => {
    const xerc20D = await hre.deployments.get("xZAI-Proxy");

    const e18 = 10n ** 18n;
    const xerc20 = await hre.ethers.getContractAt("XERC20", xerc20D.address);

    const conifgLocal = config[hre.network.name];
    assert(!!conifgLocal, `Config not found for ${hre.network.name}`);

    const limit = params.limit === "" ? 0 : parseInt(params.limit);
    const limitE18 = BigInt(limit) * e18;

    console.log(`Setting limits for xERC20 - ${xerc20.target}`);
    console.log(
      `Setting limits for bridge ${conifgLocal.connext} to ${limitE18}`
    );
    await waitForTx(
      await xerc20.setLimits(conifgLocal.connext, limitE18, limitE18)
    );

    const lockboxD = await hre.deployments.getOrNull("xZaiLockbox");
    if (lockboxD) {
      console.log(`Setting lockbox as ${lockboxD.address}`);
      await waitForTx(await xerc20.setLockbox(lockboxD.address));
    } else {
      console.log(`No lockbox found, skipping connecting lockbox`);
    }
  });
