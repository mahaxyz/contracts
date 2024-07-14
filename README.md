# MAHA Contracts

[![Foundry Build](https://github.com/mahaxyz/contracts/actions/workflows/foundry.yml/badge.svg)](https://github.com/mahaxyz/contracts/actions/workflows/foundry.yml)
[![codecov](https://codecov.io/github/mahaxyz/contracts/graph/badge.svg?token=1F8SF7LANW)](https://codecov.io/github/mahaxyz/contracts)
[![NPM Version](https://img.shields.io/npm/v/%40zerolendxyz%2Fone)](https://www.npmjs.com/package/@mahaxyz/contracts)

This repo contains all the smart contracts code that is used for the MAHA.xyz protocol. The MAHA protocol governs ZAI. A decentralized stablecoin that allows users to execute leverage on assets within the ethersphere

The ZAI direct deposit and peg stability modules are written in less than 600 lines of code.

## Documentation

- [docs.maha.xyz](https://docs.maha.xyz/) - Contains a high level overview of the entire protocol including architecture documentation.
- [wiki pages](https://github.com/mahaxyz/contracts/wiki) - The wiki pages contains the technical documentation for each contract and what they do.
- [test folders](./test) - The unit tests for the protocol are also documented and can be browsed through for insights about how each test works.

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

---

For any questions or queries, feel free to reach out to us on [Discord](https://discord.gg/mahadao)
