import dvns from "./dvn-deployments.json";
import deployments from "./lz-chain-deployments.json";

export interface IL0Config {
  eid: number;
  confirmations: number;
  optionalDVNThreshold: number;
  requiredDVNs: string[];
  contract: "OFTAdapter" | "OFT";
  libraries: {
    endpoint: string;
    sendLib302: string;
    receiveLib302: string;
    executor: string;
  };
  dvns: {
    [name: string]: string; // list all the valid DVNs here and we'll match them when connecting the contracts
  };
}

export type IL0ConfigKey =
  | "arbitrum"
  | "base"
  | "sonic"
  | "bsc"
  | "linea"
  | "mainnet"
  // | "optimism"
  // | "scroll"
  | "xlayer";

export type IL0ConfigMapping = {
  [key in IL0ConfigKey]: IL0Config;
};

const pluckDVNs = (network: string, blacklist: string[] = []) => {
  const _dvns: {
    [name: string]: string;
  } = {};
  const providers = Object.keys(dvns);
  for (let index = 0; index < providers.length; index++) {
    const provider = providers[index];
    if (
      !!dvns[provider][network] &&
      !blacklist.includes(provider) &&
      !provider.includes("lzRead")
    )
      _dvns[provider] = dvns[provider][network];
  }

  return _dvns;
};

const pluckLibraries = (network: string) => {
  return {
    sendLib302: deployments[network].sendUln302,
    receiveLib302: deployments[network].receiveUln302,
    executor: deployments[network].executor,
    endpoint: deployments[network].endpointV2,
  };
};

const pluckEid = (network: string) => deployments[network].eid;

const blacklist = ["BCW_Group"];

export const config: IL0ConfigMapping = {
  linea: {
    eid: pluckEid("Linea-Mainnet"),
    contract: "OFT",
    confirmations: 15,
    optionalDVNThreshold: 2,
    libraries: pluckLibraries("Linea-Mainnet"),
    dvns: pluckDVNs("linea", blacklist),
    requiredDVNs: ["LayerZero_Labs"],
  },
  sonic: {
    eid: pluckEid("Sonic"),
    contract: "OFT",
    confirmations: 15,
    optionalDVNThreshold: 1,
    libraries: pluckLibraries("Sonic"),
    dvns: pluckDVNs("sonic", blacklist),
    requiredDVNs: ["LayerZero_Labs"],
  },
  arbitrum: {
    eid: pluckEid("Arbitrum-Mainnet"),
    contract: "OFT",
    confirmations: 15,
    optionalDVNThreshold: 2,
    libraries: pluckLibraries("Arbitrum-Mainnet"),
    dvns: pluckDVNs("arbitrum", blacklist),
    requiredDVNs: ["LayerZero_Labs"],
  },
  mainnet: {
    eid: pluckEid("Ethereum-Mainnet"),
    contract: "OFTAdapter",
    confirmations: 5,
    optionalDVNThreshold: 2,
    libraries: pluckLibraries("Ethereum-Mainnet"),
    dvns: pluckDVNs("ethereum", blacklist),
    requiredDVNs: ["LayerZero_Labs"],
  },
  base: {
    eid: pluckEid("Base-Mainnet"),
    contract: "OFT",
    confirmations: 15,
    optionalDVNThreshold: 2,
    libraries: pluckLibraries("Base-Mainnet"),
    dvns: pluckDVNs("base", blacklist),
    requiredDVNs: ["LayerZero_Labs"],
  },
  bsc: {
    eid: pluckEid("Binance-Smart-Chain-Mainnet"),
    contract: "OFT",
    confirmations: 15,
    optionalDVNThreshold: 2,
    libraries: pluckLibraries("Binance-Smart-Chain-Mainnet"),
    dvns: pluckDVNs("bsc", blacklist),
    requiredDVNs: ["LayerZero_Labs"],
  },
  xlayer: {
    eid: pluckEid("X-Layer-Mainnet"),
    contract: "OFT",
    confirmations: 15,
    optionalDVNThreshold: 2,
    libraries: pluckLibraries("X-Layer-Mainnet"),
    dvns: pluckDVNs("xlayer", blacklist),
    requiredDVNs: ["LayerZero_Labs"],
  },
};
