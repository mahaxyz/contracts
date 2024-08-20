// layerzero.config.ts

import { EndpointId } from "@layerzerolabs/lz-definitions";
import type {
  OAppOmniGraphHardhat,
  OmniPointHardhat,
} from "@layerzerolabs/toolbox-hardhat";
import { config } from "./tasks/layerzero/config";

// Define the Amoy (Polygon) contract
// address can also be specified for deployed contracts.
const xlayerContract: OmniPointHardhat = {
  eid: EndpointId.XLAYER_V2_MAINNET,
  contractName: "ZaiStablecoinOFT",
};

const mainnetContract: OmniPointHardhat = {
  eid: EndpointId.ETHEREUM_V2_MAINNET,
  contractName: "ZaiStablecoinOFTAdapter",
};

const val: OAppOmniGraphHardhat = {
  // Define the contracts to be deployed on each network
  // Each contract is associated with a specific blockchain.
  contracts: [
    {
      contract: xlayerContract,
    },
    {
      contract: mainnetContract,
    },
  ],
  // Define the pathway between each contract.
  // This allows for cross-chain communication using LayerZero.
  connections: [
    {
      to: xlayerContract,
      from: mainnetContract,
      config: {
        // Required Send Library Address on BSC
        sendLibrary: config.mainnet.libraries.sendLib302,
        // Required Receive Library Config
        receiveLibraryConfig: {
          // Required Receive Library Address on BSC
          receiveLibrary: config.mainnet.libraries.receiveLib302,
          // Optional Grace Period for Switching Receive Library Address on BSC
          gracePeriod: BigInt(3600),
        },
        sendConfig: {
          executorConfig: {
            maxMessageSize: 10000,
            executor: config.xlayer.libraries.executor,
          },
          ulnConfig: {
            // The number of block confirmations to wait on BSC before emitting the message from the source chain (BSC).
            confirmations: BigInt(config.mainnet.config.confirmations),
            // The address of the DVNs you will pay to verify a sent message on the source chain (BSC).
            // The destination tx will wait until ALL `requiredDVNs` verify the message.
            requiredDVNs: config.mainnet.config.sendDVNs.xlayer.requiredDVNs,
            // The address of the DVNs you will pay to verify a sent message on the source chain (BSC).
            // The destination tx will wait until the configured threshold of `optionalDVNs` verify a message.
            optionalDVNs: config.mainnet.config.sendDVNs.xlayer.requiredDVNs,
            // The number of `optionalDVNs` that need to successfully verify the message for it to be considered Verified.
            optionalDVNThreshold:
              config.mainnet.config.sendDVNs.xlayer.optionalDVNThreshold,
          },
        },
      },
    },
    // {
    //   to: mainnetContract,
    //   from: xlayerContract,
    // },
  ],
};

export default val;
