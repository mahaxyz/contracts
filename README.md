# MAHA Contracts

[![Foundry Build](https://github.com/mahaxyz/contracts/actions/workflows/foundry.yml/badge.svg)](https://github.com/mahaxyz/contracts/actions/workflows/foundry.yml)
[![codecov](https://codecov.io/gh/mahaxyz/contracts/graph/badge.svg?token=N2WZ1HFD9P)](https://codecov.io/gh/mahaxyz/contracts)
[![NPM Version](https://img.shields.io/npm/v/%40mahaxyz%2Fcontracts)](https://www.npmjs.com/package/@mahaxyz/contracts)

This repo contains all the smart contracts code that is used for the MAHA.xyz protocol. The MAHA protocol governs ZAI. A decentralized stablecoin that allows users to execute leverage on assets within the ethersphere.

To use the contracts in your solidity project or integrate with your frontend (using ethers v6), you can use the following npm package.

```
yarn add --dev @mahaxyz/contracts
```

or

```
npm install --save-dev @mahaxyz/contracts
```

## Tests

There are two test suites that this repository uses.

- [Foundry](./test/forge) - Foundry is used to conduct various fuzzing and invariant tests.
- [Certora](./test/certora) - Certora is used to conduct all kinds of formal verification tests. This is more in-depth than the foundry tests but run a lot slower.

To compile and run the unit tests, simply run the following commands.

```
yarn
yarn compile
yarn test
```

Unit test coverages for foundry can be found [here](https://mahaxyz.github.io/contracts/).

## Deploy Instructions

To deploy the contracts, we use [hardat-deploy](https://github.com/wighawag/hardhat-deploy) to deploy the various contracts. Deployments are saved in the [deployments](./deployments/) folder and synced with our npm repository. Open the [deploy](./deploy/) folder to view the scripts that can be executed.

The below command is an example of how to execute the [deploy-zai.ts](./deploy/deploy-zai.ts) script.

```
npx hardhat deploy --tags ZAIStablecoin --network mainnet
```

## Documentation

![data-flow](./.github/dataflow-simple.png)

The ZAI stablecoin is incredibly minimal. With the [core modules](./contracts/core/) written in less than 400 lines of code. At the crux of the stablecoin is the [Peg-stability Module](./contracts/core/psm/) and the [Direct Deposit Module](./contracts/core/direct-deposit/). These module control the stability and the growth of ZAI.

![incentive-flow](./.github/incentiveflow-simple.png)

The incentive model is designed in such a way that there's a postive feedback loop for the growth of ZAI based on how much borrowing demand and interest fees ZAI generates.

The following links give more information about the various components and go more in-depth.

- [docs.maha.xyz](https://docs.maha.xyz/) - Contains a high level overview of the entire protocol including architecture documentation.
- [wiki pages](https://github.com/mahaxyz/contracts/wiki) - The wiki pages contains the technical documentation for each contract and what they do.
- [test folders](./test) - The unit tests for the protocol are also documented and can be browsed through for insights about how each test works.

---

For any questions or queries, feel free to reach out to us on [Discord](https://discord.gg/mahadao)
