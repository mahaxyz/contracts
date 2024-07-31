interface IConfig {
  [key: string]: {
    connext: string;
    domainId: number;
    chainId: number;
  };
}
export const config: IConfig = {
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
