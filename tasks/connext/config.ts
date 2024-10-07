interface IConfig {
  [key: string]: {
    connext: string;
    domainId: number;
    chainId: number;

    usdc: string;
    zUsdc: string;
    swapKeyNextUSDC: string;
  };
}

export const config: IConfig = {
  arbitrum: {
    connext: "0xEE9deC2712cCE65174B561151701Bf54b99C24C8",
    domainId: 1634886255,
    chainId: 42161,
    usdc: "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
    zUsdc: "0x8c556cf37faa0eedac7ae665f1bb0fbd4b2eae36",
    swapKeyNextUSDC:
      "0x6d9af4a33ed4034765652ab0f44205952bc6d92198d3ef78fe3fb2b078d0941c",
  },
  mainnet: {
    connext: "0x8898B472C54c31894e3B9bb83cEA802a5d0e63C6",
    domainId: 6648936,
    chainId: 1,
    usdc: "",
    zUsdc: "",
    swapKeyNextUSDC: "",
  },
  base: {
    connext: "0xB8448C6f7f7887D36DcA487370778e419e9ebE3F",
    domainId: 1650553709,
    chainId: 8453,
    usdc: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
    zUsdc: "0x1ede59e0d39B14c038698B1036BDE9a4819C86D4",
    swapKeyNextUSDC:
      "0x6d9af4a33ed4034765652ab0f44205952bc6d92198d3ef78fe3fb2b078d0941c",
  },
  arb_sepolia: {
    connext: "0x1780Ac087Cbe84CA8feb75C0Fb61878971175eb8",
    domainId: 1633842021,
    chainId: 421614,
    usdc: "",
    zUsdc: "",
    swapKeyNextUSDC: "",
  },
  sepolia: {
    connext: "0x445fbf9cCbaf7d557fd771d56937E94397f43965",
    domainId: 1936027759,
    chainId: 11155111,
    usdc: "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
    zUsdc: "0x8c556cf37faa0eedac7ae665f1bb0fbd4b2eae36",
    swapKeyNextUSDC: "",
  },
};
