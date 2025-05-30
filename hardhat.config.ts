import "@gelatonetwork/web3-functions-sdk/hardhat-plugin";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "hardhat-dependency-compiler";
import "hardhat-deploy";
import "hardhat-tracer";
import "solidity-coverage";
import "solidity-docgen";
import { HardhatUserConfig } from "hardhat/config";
import { keccak256 } from "ethers";
import { loadTasks } from "./scripts/utils";
import dotenv from "dotenv";
dotenv.config();

// const defaultAccount = {
//   mnemonic:
//     process.env.SEED_PHRASE ||
//     "test test test test test test test test test test test junk",
//   path: "m/44'/60'/0'/0",
//   initialIndex: 0,
//   count: 20,
//   passphrase: "",
// };

const defaultAccount = [
  process.env.DEPLOYER_KEY || keccak256("0x1212"),
  process.env.ZAI_DEPLOYER_KEY || keccak256("0x1234"),
  process.env.SZAI_DEPLOYER_KEY || keccak256("0x1233"),
];

const SKIP_LOAD = process.env.SKIP_LOAD === "true";

// Prevent to load tasks before compilation and typechain
if (!SKIP_LOAD) loadTasks(["misc", "layerzero"]);

const _network = (url: string, gasPrice: number | "auto" = "auto") => ({
  url,
  accounts: defaultAccount,
  saveDeployments: true,
  gasPrice,
});

const config: HardhatUserConfig = {
  w3f: {
    rootDir: "./web3-functions",
    debug: false,
    networks: ["linea", "base", "mainnet"], // (multiChainProvider) injects provider for these networks
  },
  abiExporter: {
    path: "./abi",
    runOnCompile: true,
    clear: true,
    spacing: 2,
    format: "minimal",
  },
  docgen: {
    pages: "files",
    exclude: ["interfaces", "tests"],
  },
  gasReporter: {
    // @ts-ignore
    reportFormat: "terminal",
    outputFile: "coverage/gasReport.txt",
    noColors: true,
    forceTerminalOutput: true,
    forceTerminalOutputFormat: "terminal",
  },
  dependencyCompiler: {
    paths: [
      "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol",
    ],
  },
  typechain: {
    outDir: "types",
    target: "ethers-v6",
  },
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      // forking: {
      //   url: `https://rpc.ankr.com/eth`,
      // },
      accounts: defaultAccount.map((pk) => ({
        balance: "1000000000000000000000000",
        privateKey: pk,
      })),
    },
    arbitrum: _network("https://arb1.arbitrum.io/rpc"),
    base: _network("https://mainnet.base.org"),
    bsc: _network("https://bsc-dataseed1.bnbchain.org"),
    blast: _network("https://rpc.blast.io"),
    linea: _network("https://rpc.linea.build"),
    sonic: _network("https://rpc.soniclabs.com"),
    unichain: _network("https://mainnet.unichain.org"),
    mainnet: _network("https://eth.merkle.io"),
    zircuit: _network("https://zircuit-mainnet.drpc.org"),
    optimism: _network("https://mainnet.optimism.io"),
    scroll: _network("https://rpc.ankr.com/scroll", 1100000000),
    sepolia: _network("https://rpc2.sepolia.org"),
    xlayer: _network("https://xlayerrpc.okx.com"),
  },
  namedAccounts: {
    deployer: 0,
    zaiDeployer: 1,
    szaiDeployer: 2,
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_KEY || "",
      sepolia: process.env.ETHERSCAN_KEY || "",
      base: process.env.BASESCAN_KEY || "",
      blast: process.env.BLASTSCAN_KEY || "",
      bsc: process.env.BSCSCAN_KEY || "",
      linea: process.env.LINEASCAN_KEY || "",
      optimisticEthereum: process.env.OP_ETHERSCAN_KEY || "",
      scroll: process.env.SCROLLSCAN_KEY || "",
      unichain: process.env.UNISCAN_KEY || "",
      sonic: process.env.SONICSCAN_KEY || "",
      arbitrumOne: process.env.ARBISCAN_KEY || "",
      xlayer: "test",
    },
    customChains: [
      {
        network: "xlayer",
        chainId: 196,
        urls: {
          apiURL:
            "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/XLAYER",
          browserURL: "https://www.oklink.com/xlayer",
        },
      },
      {
        network: "sonic",
        chainId: 146,
        urls: {
          apiURL: "https://api.sonicscan.org/api",
          browserURL: "https://sonicscan.org",
        },
      },
      {
        network: "linea",
        chainId: 59144,
        urls: {
          apiURL: "https://api.lineascan.build/api",
          browserURL: "https://lineascan.build",
        },
      },
      {
        network: "blast",
        chainId: 81457,
        urls: {
          apiURL: "https://api.blastscan.io/api",
          browserURL: "https://blastscan.io",
        },
      },
      {
        network: "scroll",
        chainId: 534352,
        urls: {
          apiURL: "https://api.scrollscan.com/api",
          browserURL: "https://scrollscan.com",
        },
      },
      {
        network: "unichain",
        chainId: 130,
        urls: {
          apiURL: "https://api.uniscan.xyz/api",
          browserURL: "https://uniscan.xyz",
        },
      },
    ],
  },
};

export default config;
