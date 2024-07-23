# Direct Deposit Module

The Zai Direct Deposit (DDM) Module is a specialized liquidty contract that is handle liqudity provisioning of ZAI across various lending pools (like ZeroLend, Morpho, Aave etc..). The DD module is roughly inspired by MakerDAO's DAI Direct Deposit Module (D3M).

The DD module consists of three components.

- The Direct Deposit Hub ([DDHub.sol](./DDHub.sol)): The hub mainly for responsible for managing all the various pools
- A Direct Deposit Pool (like the [MetaMorpho](./pools/DDMetaMorpho.sol) pool): Pools that implement the logic of supplying and withdrawing from various pools
- A Direct Deposit Plan ([DDOperatorPlan.sol](./plans/DDOperatorPlan.sol)): Plans that manage the supply of ZAI across the various pools

To ensure the safety of the DD module, multiple levels of debt ceilings are kept in place so that a particular plan or pool does not beyond it's desired thresholds. The debt minted by a particular is always the minimum of the various debt ceilings.

- **Global Debt Ceiling**: A global debt ceiling is implemented at the [hub](./DDHub.sol) to ensure that the entirity of the ZAI minted by the protocol is never more than a certain threshold. This is a paramter that can only be set by governance

- **Pool Debt Ceiling**: An individual pool-level debt ceiling is further implemented to ensure that each pool has it's own limits.

- **Pool Plan Target**: Each pools has a plan which decides how much ideal exposure the pools should have in terms of ZAI.
