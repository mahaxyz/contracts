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
