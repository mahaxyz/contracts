/**
  Script to setup OFTs for the token on the various networks.

  npx hardhat setup-oft-all --network base
  npx hardhat setup-oft-all --network linea
  npx hardhat setup-oft-all --network mainnet
  npx hardhat setup-oft-all --network sonic
  npx hardhat setup-oft-all --network bsc
  npx hardhat setup-oft-all --network unichain
  npx hardhat setup-oft-all --network xlayer

  // these chains we don't want to get connected with
  npx hardhat setup-oft-all --network arbitrum
  npx hardhat setup-oft-all --network blast
  npx hardhat setup-oft-all --network optimism
  npx hardhat setup-oft-all --network scroll
 */
import { config } from "./config";
import { task } from "hardhat/config";
import { _writeGnosisSafeTransaction } from "./utils";
import { prepareTimelockData } from "../../scripts/prepare-timelock";

task(`setup-oft-all`, `Sets up the OFT with the right DVNs`).setAction(
  async (_, hre) => {
    const c = config[hre.network.name];
    if (!c) throw new Error("cannot find connection");

    const pendingTxs1 = await hre.run("setup-oft", { token: "maha" });
    // const pendingTxs2 = await hre.run("setup-oft", { token: "zai" });
    const pendingTxs = [...pendingTxs1];

    const timelockTxs = pendingTxs.filter((t) => t.timelock).map((t) => t.tx);
    const safeTxs = pendingTxs.filter((t) => !t.timelock).map((t) => t.tx);

    const timelock = await hre.deployments.get("MAHATimelockController");
    const safe = await hre.deployments.get("GnosisSafe");

    if (timelockTxs.length > 0) {
      const tx = await prepareTimelockData(
        hre,
        safe.address,
        timelockTxs,
        timelock.address
      );
      console.log("writing timelock txs for schedule");
      _writeGnosisSafeTransaction(
        `execute/tx-timelock-${hre.network.name}-schedule.json`,
        [tx.schedule]
      );
      console.log("writing timelock txs for execute");
      _writeGnosisSafeTransaction(
        `execute/tx-timelock-${hre.network.name}-execute.json`,
        [tx.execute]
      );
    }

    if (safeTxs.length > 0) {
      console.log("writing safe txs");
      _writeGnosisSafeTransaction(
        `execute/tx-safe-${hre.network.name}-execute.json`,
        safeTxs
      );
    }
  }
);
