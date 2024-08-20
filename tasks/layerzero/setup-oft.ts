import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config, IL0Config } from "./config";
import _ from "underscore";

const _fetchAndSortDVNS = (
  conf: IL0Config,
  dvns: string[] = [],
  remoteDvns: string[] = []
) => {
  const commonDVNs = _.intersection(dvns, remoteDvns);
  const mappedDVNs = commonDVNs.map((dvn) => conf.dvns[dvn]);
  return mappedDVNs.sort();
};

task(`setup-oft`, `Sets up the OFT with the right DVNs`)
  .addParam("token", "either zai or maha")
  .setAction(async ({ token }, hre) => {
    const c = config[hre.network.name];
    if (!c) throw new Error("cannot find connection");

    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "MAHA";
    const contractName = `${contractNameToken}${c.contract}`;

    const remoteConnections = Object.keys(config).filter(
      (c) => c !== hre.network.name
    );

    const ulnConfigStructType =
      "tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)";
    const configTypeExecutorStruct =
      "tuple(uint32 maxMessageSize, address executorAddress)";

    const encoder = hre.ethers.AbiCoder.defaultAbiCoder();

    const oftD = await hre.deployments.get(contractName);
    const oft = await hre.ethers.getContractAt("OFT", oftD.address);
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    const execConfigData = {
      maxMessageSize: 10000,
      executorAddress: c.libraries.executor,
    };

    // taken from https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#setting-send-config
    for (let index = 0; index < remoteConnections.length; index++) {
      const remoteNetwork = remoteConnections[index];
      const r = config[remoteNetwork];

      console.log(
        "setting up DVN routes from",
        hre.network.name,
        "to remote network",
        remoteNetwork
      );
      const requiredDVNs = _fetchAndSortDVNS(c, c.requiredDVNs, r.requiredDVNs);
      const optionalDVNs = _fetchAndSortDVNS(c, c.optionalDVNs, r.optionalDVNs);

      if (requiredDVNs.length === 0 && optionalDVNs.length === 0) {
        console.log("no DVNs to set up for remote network", remoteNetwork);
        continue;
      } else {
        console.log("using requiredDVNs:", requiredDVNs);
        console.log("using optionalDVNs:", optionalDVNs);
      }

      const ulnConfigDataSend = {
        confirmations: c.confirmations,
        requiredDVNCount: requiredDVNs.length,
        optionalDVNCount: optionalDVNs.length,
        optionalDVNThreshold: c.optionalDVNThreshold,
        requiredDVNs: requiredDVNs,
        optionalDVNs: optionalDVNs,
      };

      const ulnConfigDataRecv = {
        confirmations: r.confirmations,
        requiredDVNCount: requiredDVNs.length,
        optionalDVNCount: optionalDVNs.length,
        optionalDVNThreshold: r.optionalDVNThreshold,
        requiredDVNs: requiredDVNs,
        optionalDVNs: optionalDVNs,
      };

      const setConfigParamUlnSend = {
        eid: r.eid,
        configType: 2,
        config: encoder.encode([ulnConfigStructType], [ulnConfigDataSend]),
      };

      const setConfigParamUlnRecv = {
        eid: r.eid,
        configType: 2,
        config: encoder.encode([ulnConfigStructType], [ulnConfigDataRecv]),
      };

      const setConfigParamExecutor = {
        eid: r.eid,
        configType: 1,
        config: encoder.encode([configTypeExecutorStruct], [execConfigData]),
      };

      // // setup the send config
      // await waitForTx(
      //   await endpoint.setConfig(oft.target, c.libraries.sendLib302, [
      //     setConfigParamUlnSend,
      //     setConfigParamExecutor,
      //   ]),
      //   2
      // );

      // // setup the receive config
      // await waitForTx(
      //   await endpoint.setConfig(oft.target, c.libraries.receiveLib302, [
      //     setConfigParamUlnRecv,
      //   ])
      // );
    }
  });
