import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "hardhat-contract-sizer";
// import "hardhat-typechain";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-dependency-compiler";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";

import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  defaultNetwork: "lineaSepolia",
  dependencyCompiler: {
    paths: [
      "@zerolendxyz/core-v3/contracts/protocol/tokenization/VariableDebtToken.sol",
      "@openzeppelin/contracts/utils/Context.sol",
      "@openzeppelin/contracts/token/ERC20/ERC20.sol",
    ],
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      accounts: [
        {
          privateKey: process.env.WALLET_PRIVATE_KEY || "",
          balance: "100000000000000000000",
        },
      ],
      forking: {
        url: "https://rpc.linea.build",
      },
    },
    linea: {
      url: "https://rpc.linea.build",
      accounts: [process.env.WALLET_PRIVATE_KEY || ""],
    },
    blastSepolia: {
      url: "https://sepolia.blast.io",
      accounts: [process.env.WALLET_PRIVATE_KEY || ""],
      chainId: 168587773,
      gasPrice: 1000000000,
    },
    sepolia: {
      url: "https://public.stackup.sh/api/v1/node/ethereum-sepolia",
      accounts: [process.env.WALLET_PRIVATE_KEY || ""],
      chainId: 11155111,
      allowUnlimitedContractSize: true,
    },
    lineaSepolia: {
      url: "https://rpc.sepolia.linea.build",
      accounts: [process.env.WALLET_PRIVATE_KEY || ""],
      chainId: 59141
    },
  },
  gasReporter: {
    enabled: true,
  },
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: { yul: false }
      },
    },
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  mocha: {
    timeout: 0,
    bail: true,
  },
  etherscan: {
    apiKey: {
      manta: "123",
      blast: "BIMMMKKB7I2HMABKJ9C2U1EH6PIIZCSPEF",
      linea: "Y7TKICWCPM22AUWWF3TXXAFCMPT6XTVHJI",
      sepolia: "V1S3WJ3ZP251TF71MWQWEMYRZZ48XPUIME",
      lineaSepolia: "Y7TKICWCPM22AUWWF3TXXAFCMPT6XTVHJI"
      // [eEthereumNetwork.main]: "YKI5VW86TBDGWQZQFHIA3AACABTUUFMYPV",
    },
    customChains: [
      {
        network: "manta",
        chainId: 169,
        urls: {
          apiURL: "https://pacific-explorer.manta.network/api",
          browserURL: "https://pacific-explorer.manta.network",
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
        network: "linea",
        chainId: 59144,
        urls: {
          apiURL: "https://api.lineascan.build/api",
          browserURL: "https://lineascan.build",
        },
      },
    ],
  },
};

export default config;
