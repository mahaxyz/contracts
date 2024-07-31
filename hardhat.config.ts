import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-dependency-compiler";
import "hardhat-abi-exporter";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import "solidity-coverage";
import "solidity-docgen";
import "hardhat-tracer";

import "@typechain/hardhat";
import "@nomicfoundation/hardhat-chai-matchers";

import dotenv from "dotenv";
dotenv.config();

const defaultAccount = {
  mnemonic:
    process.env.SEED_PHRASE ||
    "test test test test test test test test test test test junk",
  path: "m/44'/60'/0'/0",
  initialIndex: 0,
  count: 20,
  passphrase: "",
};

const config: HardhatUserConfig = {
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
      forking: {
        url: `https://rpc.ankr.com/eth`,
      },
    },
    mainnet: {
      url: `https://rpc.ankr.com/eth`,
      accounts: defaultAccount,
      saveDeployments: true,
    },
    sepolia: {
      url: `https://rpc2.sepolia.org`,
      accounts: defaultAccount,
      saveDeployments: true,
    },
    arb_sepolia: {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      accounts: defaultAccount,
      saveDeployments: true,
    },
  },
  namedAccounts: {
    deployer: 0,
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_KEY || "",
      sepolia: process.env.ETHERSCAN_KEY || "",
      arbitrumSepolia: process.env.ARBISCAN_KEY || "",
    },
  },
};

export default config;
