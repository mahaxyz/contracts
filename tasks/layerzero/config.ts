interface IConfig {
  [key: string]: {
    eid: number;
    network: string;
    endpoint: string;
    contract: "ZaiStablecoinOFTAdapter" | "ZaiStablecoinOFT";

    libraries: {
      sendLib302: string;
      receiveLib302: string;
      executor: string;
    };

    config: {
      confirmations: number;
      sendDVNs: {
        [network: string]: {
          optionalDVNThreshold: number;
          requiredDVNs: string[];
          optionalDVNs: string[];
        };
      };
    };
  };
}

export const config: IConfig = {
  mainnet: {
    network: "mainnet",
    eid: 30101,
    contract: "ZaiStablecoinOFTAdapter",
    libraries: {
      sendLib302: "0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1",
      receiveLib302: "0xc02Ab410f0734EFa3F14628780e6e695156024C2",
      executor: "0x173272739Bd7Aa6e4e214714048a9fE699453059",
    },
    endpoint: "0x1a44076050125825900e736c501f859c50fE728c",

    config: {
      confirmations: 5,
      sendDVNs: {
        xlayer: {
          optionalDVNThreshold: 1,
          requiredDVNs: [
            "0x589dedbd617e0cbcb916a9223f4d1300c294236b", // layerzero labs
          ],
          optionalDVNs: [
            "0x380275805876ff19055ea900cdb2b46a94ecf20d", // horizen
            "0x8ddf05f9a5c488b4973897e278b58895bf87cb24", // polyhedra
            "0xa59ba433ac34d2927232918ef5b2eaafcf130ba5", // nethermind
          ],
        },
      },
    },
  },
  base: {
    network: "base",
    eid: 30184,
    contract: "ZaiStablecoinOFTAdapter",
    libraries: {
      sendLib302: "0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2",
      receiveLib302: "0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf",
      executor: "0x2CCA08ae69E0C44b18a57Ab2A87644234dAebaE4",
    },
    endpoint: "0x1a44076050125825900e736c501f859c50fE728c",
    config: {
      confirmations: 5,
      sendDVNs: {},
    },
  },
  xlayer: {
    network: "xlayer",
    eid: 30274,
    contract: "ZaiStablecoinOFT",
    endpoint: "0x1a44076050125825900e736c501f859c50fE728c",
    libraries: {
      sendLib302: "0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043",
      receiveLib302: "0x2367325334447C5E1E0f1b3a6fB947b262F58312",
      executor: "0xcCE466a522984415bC91338c232d98869193D46e",
    },
    config: {
      confirmations: 10,
      sendDVNs: {
        mainnet: {
          optionalDVNThreshold: 1,
          requiredDVNs: [
            "0x9c061c9a4782294eef65ef28cb88233a987f4bdd", // layerzero labs
          ],
          optionalDVNs: [
            "0x28af4dadbc5066e994986e8bb105240023dc44b6", // nethermind
            "0x8ddf05f9a5c488b4973897e278b58895bf87cb24", // polyhedra
            "0xdd7b5e1db4aafd5c8ec3b764efb8ed265aa5445b", // horizen
          ],
        },
      },
    },
  },
};
