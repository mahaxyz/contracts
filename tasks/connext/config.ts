interface IConfig {
  [key: string]: {
    connext: string;
    domainId: number;
    chainId: number;
  };
}

export const config: IConfig = {
  arbitrum: {
    connext: "0xEE9deC2712cCE65174B561151701Bf54b99C24C8",
    domainId: 1634886255,
    chainId: 42161,
  },
  mainnet: {
    connext: "0x8898B472C54c31894e3B9bb83cEA802a5d0e63C6",
    domainId: 6648936,
    chainId: 1,
  },
  arb_sepolia: {
    connext: "0x1780Ac087Cbe84CA8feb75C0Fb61878971175eb8",
    domainId: 1633842021,
    chainId: 421614,
  },
  sepolia: {
    connext: "0x445fbf9cCbaf7d557fd771d56937E94397f43965",
    domainId: 1936027759,
    chainId: 11155111,
  },
};
