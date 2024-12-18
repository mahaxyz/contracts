/**
  Script to setup OFTs for the token on the various networks.

  npx hardhat setup-oft --network arbitrum --token zai
  npx hardhat setup-oft --network base --token zai
  npx hardhat setup-oft --network bsc --token zai
  npx hardhat setup-oft --network xlayer --token zai
  npx hardhat setup-oft --network linea --token zai
  npx hardhat setup-oft --network mainnet --token zai
 */
import _ from "underscore";
import { config, IL0Config, IL0ConfigKey } from "./config";
import { EnforcedOptionParamStruct } from "../../types/@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT";
import { Options } from "@layerzerolabs/lz-v2-utilities";
import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { get } from "../../scripts/helpers";
import { ContractTransaction, zeroPadValue } from "ethers";
import { _writeGnosisSafeTransaction } from "./utils";
import { prepareTimelockData } from "../../scripts/prepare-timelock";

const yellowLog = (text: string) => console.log(`\x1b[33m${text}\x1b[0m`);

const _fetchAndSortDVNS = (
  conf: IL0Config,
  dvns: string[] = [],
  remoteDvns: string[] = [],
  currentDvs: string[] = [],
  limit: number = 5
) => {
  const commonDVNs = _.intersection(dvns, remoteDvns);

  if (currentDvs.length > 0) {
    const keys = Object.keys(conf.dvns);
    const currentDvsToNames = currentDvs
      .map((dvn) =>
        keys.find((k) => conf.dvns[k].toLowerCase() === dvn.toLowerCase())
      )
      .sort()
      .filter((d) => !!d) as string[];

    const existingDvns = _.intersection(currentDvsToNames, commonDVNs);
    if (existingDvns.length == limit)
      return existingDvns.map((dvn) => conf.dvns[dvn]).sort();
  }

  return _.first(commonDVNs.map((dvn) => conf.dvns[dvn]).sort(), limit);
};

const _fetchOptionalDVNs = (conf: IL0Config) => {
  const dvns = Object.keys(conf.dvns);
  return _.difference(dvns, conf.requiredDVNs);
};

task(`setup-oft`, `Sets up the OFT with the right DVNs`)
  .addParam("token", "either zai or maha")
  .setAction(async ({ token }, hre) => {
    const c = config[hre.network.name];
    if (!c) throw new Error("cannot find connection");

    const [deployer] = await hre.ethers.getSigners();

    const remoteConnections = Object.keys(config).filter(
      (c) => c !== hre.network.name
    ) as IL0ConfigKey[];

    const ulnConfigStructType =
      "tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)";
    const configTypeExecutorStruct =
      "tuple(uint32 maxMessageSize, address executorAddress)";

    const encoder = hre.ethers.AbiCoder.defaultAbiCoder();

    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "MAHA";
    const contractName = `${contractNameToken}${c.contract}`;

    const timelock = await hre.deployments.get("MAHATimelockController");
    const safe = await hre.deployments.get("GnosisSafe");
    const oftD = await hre.deployments.get(contractName);
    const oft = await hre.ethers.getContractAt(
      "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol:OFT",
      oftD.address
    );
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    console.log("using layerzero endpoint", endpoint.target);
    console.log("using oft", oft.target);

    const execConfigData = {
      maxMessageSize: 10000,
      executorAddress: c.libraries.executor,
    };

    const options = Options.newOptions()
      .addExecutorLzReceiveOption(200000, 0)
      .toHex()
      .toString();

    const delegate = await endpoint.delegates(oft.target);
    const shouldMock =
      delegate.toLowerCase() !== deployer.address.toLowerCase();
    const pendingTxs: ContractTransaction[] = [];

    if (
      shouldMock &&
      delegate.toLowerCase() !== timelock.address.toLowerCase()
    ) {
      console.log("setting delegate to", timelock.address);
      const tx = await oft.setDelegate.populateTransaction(timelock.address);
      yellowLog(">> setDelegate tx added");
      pendingTxs.push(tx);
    }

    // taken from https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#setting-send-config
    for (let index = 0; index < remoteConnections.length; index++) {
      const remoteNetwork = remoteConnections[index];
      const r = config[remoteNetwork];

      console.log(
        "\n\nsetting up DVN routes from",
        hre.network.name,
        "to remote network",
        remoteNetwork,
        r.eid
      );

      const currentUlnSend = await endpoint.getConfig(
        oft.target,
        c.libraries.sendLib302,
        r.eid,
        2
      );

      const currentUlnRecv = await endpoint.getConfig(
        oft.target,
        c.libraries.receiveLib302,
        r.eid,
        2
      );

      const data = encoder.decode([ulnConfigStructType], currentUlnSend)[0];
      const currentDvnsReq = data[4];
      const currentDvnsOptional = data[5];

      const requiredDVNs = _fetchAndSortDVNS(
        c,
        c.requiredDVNs,
        r.requiredDVNs,
        currentDvnsReq
      );
      const optionalDVNs = _fetchAndSortDVNS(
        c,
        _fetchOptionalDVNs(c),
        _fetchOptionalDVNs(r),
        currentDvnsOptional,
        3
      );

      const remoteContractName = `${contractNameToken}${r.contract}`;

      const remoteD = get(remoteContractName, remoteNetwork);
      const remoteOft = zeroPadValue(remoteD, 32);

      const peer = await oft.peers(r.eid);

      if (peer.toLowerCase() != remoteOft.toLowerCase()) {
        // if we can set the peer, we will set it here
        console.log("setting peer for", remoteNetwork);
        if (shouldMock) {
          const tx = await oft.setPeer.populateTransaction(r.eid, remoteOft);
          yellowLog(">> setPeer tx added");
          pendingTxs.push(tx);
        } else await waitForTx(await oft.setPeer(r.eid, remoteOft));
      }

      if (requiredDVNs.length === 0 && optionalDVNs.length === 0) {
        console.log("no DVNs to set up for remote network", remoteNetwork);
        continue;
      } else {
        console.log("using requiredDVNs:", requiredDVNs.length);
        console.log("using optionalDVNs:", optionalDVNs.length);
      }

      console.log(
        "using optionalDVNThreshold:",
        Math.min(c.optionalDVNThreshold, optionalDVNs.length)
      );

      const ulnConfigDataSend = {
        confirmations: c.confirmations,
        requiredDVNCount: requiredDVNs.length,
        optionalDVNCount: optionalDVNs.length,
        optionalDVNThreshold: Math.min(
          c.optionalDVNThreshold,
          optionalDVNs.length
        ),
        requiredDVNs: requiredDVNs,
        optionalDVNs: optionalDVNs,
      };

      const ulnConfigDataRecv = {
        confirmations: r.confirmations,
        requiredDVNCount: requiredDVNs.length,
        optionalDVNCount: optionalDVNs.length,
        optionalDVNThreshold: Math.min(
          c.optionalDVNThreshold,
          optionalDVNs.length
        ),
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

      // setup the send config
      if (currentUlnSend != setConfigParamUlnSend.config) {
        console.log("setting send config");
        if (shouldMock) {
          const tx = await endpoint.setConfig.populateTransaction(
            oft.target,
            c.libraries.sendLib302,
            [setConfigParamUlnSend, setConfigParamExecutor]
          );
          pendingTxs.push(tx);
          yellowLog(">> setConfig send tx added");
        } else
          await waitForTx(
            await endpoint.setConfig(oft.target, c.libraries.sendLib302, [
              setConfigParamUlnSend,
              setConfigParamExecutor,
            ]),
            2
          );
      } else console.log("send config already set");

      // setup the receive config
      if (currentUlnRecv != setConfigParamUlnRecv.config) {
        console.log("setting receive config");
        if (shouldMock) {
          const tx = await endpoint.setConfig.populateTransaction(
            oft.target,
            c.libraries.receiveLib302,
            [setConfigParamUlnRecv]
          );
          pendingTxs.push(tx);
          yellowLog(">> setConfig recv tx added");
        } else
          await waitForTx(
            await endpoint.setConfig(oft.target, c.libraries.receiveLib302, [
              setConfigParamUlnRecv,
            ])
          );
      } else console.log("receive config already set");

      // set enforced options
      const setOptions = await oft.enforcedOptions(r.eid, 1);
      if (setOptions !== options) {
        console.log("setting enforced options");
        const enforcedOptions: EnforcedOptionParamStruct[] =
          remoteConnections.map((r) => ({
            eid: config[r].eid,
            msgType: 1,
            options,
          }));

        if (shouldMock) {
          const tx = await oft.setEnforcedOptions.populateTransaction(
            enforcedOptions
          );
          yellowLog(">> setEnforcedOptions tx added");
          pendingTxs.push(tx);
        } else await waitForTx(await oft.setEnforcedOptions(enforcedOptions));
      } else console.log("enforced options already set");
    }

    if (shouldMock) {
      const tx = await prepareTimelockData(
        hre,
        safe.address,
        pendingTxs,
        timelock.address
      );
      _writeGnosisSafeTransaction("tx-schedule.json", [tx.schedule]);
      _writeGnosisSafeTransaction("tx-execute.json", [tx.execute]);
    }
  });
