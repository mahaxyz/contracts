/**
  Script to setup OFTs for the token on the various networks.

  npx hardhat setup-omnigov --network arbitrum
  npx hardhat setup-omnigov --network base
  npx hardhat setup-omnigov --network blast
  npx hardhat setup-omnigov --network bsc
  npx hardhat setup-omnigov --network xlayer
  npx hardhat setup-omnigov --network linea
  npx hardhat setup-omnigov --network zircuit
  npx hardhat setup-omnigov --network manta
  npx hardhat setup-omnigov --network mainnet
 */
import { config, IL0ConfigKey } from "./config";
import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { get } from "../../scripts/helpers";
import { _fetchAndSortDVNS, _fetchOptionalDVNs } from "./utils";

task(
  `setup-omnigov`,
  `Sets up the Omnichain Governance with the right DVNs`
).setAction(async (_, hre) => {
  const c = config[hre.network.name];
  if (!c) throw new Error("cannot find connection");

  const isMainnet = hre.network.name == "mainnet";

  const remoteConnections = Object.keys(config).filter((c) =>
    isMainnet ? c !== hre.network.name : c === "mainnet"
  ) as IL0ConfigKey[];

  const ulnConfigStructType =
    "tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)";
  const configTypeExecutorStruct =
    "tuple(uint32 maxMessageSize, address executorAddress)";

  const encoder = hre.ethers.AbiCoder.defaultAbiCoder();

  const contractName = isMainnet
    ? "OmnichainProposalSenderL1"
    : "OmnichainGovernanceExecutorL2";

  const remoteContractName = isMainnet
    ? "OmnichainGovernanceExecutorL2"
    : "OmnichainProposalSenderL1";

  const contractD = await hre.deployments.get(contractName);
  const contract = await hre.ethers.getContractAt(
    "OmnichainProposalSenderL1",
    contractD.address
  );

  const endpoint = await hre.ethers.getContractAt(
    "IL0EndpointV2",
    await contract.lzEndpoint()
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
      "\n\nsetting up DVN routes from",
      hre.network.name,
      "to remote network",
      remoteNetwork,
      r.eid
    );

    const requiredDVNs = _fetchAndSortDVNS(c, c.requiredDVNs, r.requiredDVNs);
    const optionalDVNs = _fetchAndSortDVNS(
      c,
      _fetchOptionalDVNs(c),
      _fetchOptionalDVNs(r),
      3
    );

    const remoteD = get(remoteContractName, remoteNetwork);

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

    const currentUlnSend = await endpoint.getConfig(
      contract.target,
      c.libraries.sendLib302,
      r.eid,
      2
    );

    const currentUlnRecv = await endpoint.getConfig(
      contract.target,
      c.libraries.receiveLib302,
      r.eid,
      2
    );

    // setup the send config
    console.log("checking send config");
    console.log(endpoint.target, contract.target);

    // (uint16 version, uint16 chainId, uint configType, bytes calldata config
    // if (currentUlnSend != setConfigParamUlnSend.config)
    // await waitForTx(
    //   await contract.setConfig(
    //     // (uint16 version,
    //     r.eid, // uint16 chainId,
    //     2, // uint configType,
    //     // bytes calldata config
    //   ]),
    //   2
    // );
    // else console.log("send config already set");

    // setup the receive config
    console.log("checking receive config");
    if (currentUlnRecv != setConfigParamUlnRecv.config && !isMainnet)
      await waitForTx(
        await endpoint.setConfig(contract.target, c.libraries.receiveLib302, [
          setConfigParamUlnRecv,
        ])
      );
    else console.log("receive config already set");

    // // set enforced options
    // const setOptions = await contract.enforcedOptions(r.eid, 1);
    // if (setOptions !== options) {
    //   console.log("setting enforced options");
    //   const enforcedOptions: EnforcedOptionParamStruct[] =
    //     remoteConnections.map((r) => ({
    //       eid: config[r].eid,
    //       msgType: 1,
    //       options,
    //     }));
    //   await waitForTx(await contract.setEnforcedOptions(enforcedOptions));
    // } else console.log("enforced options already set");

    const trustedRemote = await contract.trustedRemoteLookup(r.eid);
    if (trustedRemote.toLowerCase() !== remoteD.toLowerCase()) {
      console.log("setting trusted remote");
      await waitForTx(await contract.setTrustedRemoteAddress(r.eid, remoteD));
    }
    console.log("trusted remote already set");
  }
});
