import _ from "underscore";
import { IL0Config } from "./config";
import { ContractTransaction } from "ethers";
import fs from "fs";

export const _fetchAndSortDVNS = (
  conf: IL0Config,
  dvns: string[] = [],
  remoteDvns: string[] = [],
  limit: number = 5000,
  priority: string[] = [
    "Google_Cloud",
    "Nethermind",
    "Stargate",
    "Horizen",
    "Polyhedra",
  ]
) => {
  const commonDVNs = _.intersection(dvns, remoteDvns);
  const priorityDVNs = _.intersection(commonDVNs, priority);
  const nonPriorityDVNs = _.difference(commonDVNs, priority);
  const prioritizedDVNs = [...priorityDVNs, ...nonPriorityDVNs];
  return _.first(prioritizedDVNs.map((dvn) => conf.dvns[dvn]).sort(), limit);
};

export const _fetchOptionalDVNs = (conf: IL0Config) => {
  const dvns = Object.keys(conf.dvns);
  return _.difference(dvns, conf.requiredDVNs);
};

export const _writeGnosisSafeTransaction = (
  file: string,
  txs: ContractTransaction[]
) => {
  console.log("\n\ntransactions to schedule in safe written into tx.json");

  fs.writeFileSync(
    file,
    JSON.stringify(
      {
        version: "1.0",
        meta: {
          name: "Transactions Batch",
          description: "",
          txBuilderVersion: "1.17.1",
          createdFromSafeAddress: "",
          createdFromOwnerAddress: "",
        },
        transactions: txs.map((d) => ({ ...d, value: "0" })),
      },
      null,
      2
    )
  );
};
