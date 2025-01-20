import hre from "hardhat";
import fs from "fs";
import path from "path";
import csv from "csv-parser";
import { waitForTx } from "../utils";
import { ContractTransaction, MaxUint256 } from "ethers";

async function main() {
  const stakingD = await hre.deployments.get("OmnichainStakingToken");
  const staking = await hre.ethers.getContractAt(
    "OmnichainStakingToken",
    stakingD.address
  );
  const maha = await hre.ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    "0x554bba833518793056CF105E66aBEA330672c0dE"
  );

  // check allowance
  const [deployer] = await hre.ethers.getSigners();
  const allowance = await maha.allowance(deployer.address, staking.target);
  if (allowance == 0) {
    console.log("approving staking contract");
    await waitForTx(await maha.approve(staking.target, MaxUint256));
  }

  const results: {
    token: string;
    amount: string;
    start: string;
    end: string;
    owner: string;
    newowner: string;
  }[] = [];

  // read csv
  fs.createReadStream(path.resolve(__dirname, "snapshot.csv"))
    .pipe(csv())
    .on("data", (data) => results.push(data))
    .on("end", async () => {
      // migrate all the nfts
      let txs: ContractTransaction[] = [];
      for (let index = 0; index < results.length; index++) {
        const result = results[index];
        const amount = parseInt(result.amount);
        const owner =
          result.newowner.length > 0 ? result.newowner : result.owner;
        const start = parseInt(result.start);
        const end = parseInt(result.end);

        const migrated = await staking.migratedLockId(result.token);
        if (migrated) {
          console.log(index, "already migrated", result.token);
          continue;
        }
        console.log(
          index,
          "migrating",
          result.token,
          amount,
          start,
          end,
          owner
        );

        const e18 = 10n ** 18n;
        txs.push(
          await staking.migrate.populateTransaction(
            result.token,
            BigInt(amount) * e18,
            start,
            end,
            owner,
            {
              gasLimit: 800000,
            }
          )
        );

        if (index % 1 == 0 && txs.length > 0) {
          let nonce = await deployer.getNonce();
          const receipt = txs.map((r) =>
            deployer.sendTransaction({ ...r, nonce: nonce++ })
          );
          const results = await Promise.all(receipt);
          await waitForTx(results[results.length - 1]);
          txs = [];
        }
      }
    });
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
