# AladdinDAO

## Contract Overview

![Overview](/diagram.png)

### Token
Contracts for the LAMP token and its distribution.

### Farm
Contracts for yearn style strategies. Strategies does not auto sell rewards for underlying, but allow users to claim them instead

### Reward
Staking reward contracts for LAMP token.

### DAO
Contracts for funding and treasury

## Deployments

### KOVAN
 - DefixToken - `0x09B7C22E7e5CC7F5BE68d2Bd85d85B00101C0ee8`
 - Treasury - `0xdE5e7fc0fE5C5F88E86D3345289d2fADf95BEa1a`
 - DAO - `0x7dc55EdffB12ea3d055259C94305Ffb4Ffd8e5F5`
 - TokenDistributor - `0x4151F3ca7cdf08862EC951ddcB2b2Fc284d48F6e`
 - TokenMaster - `0xcedF9fBe161B75d8F2822C89a18c919d36369F98`
 - StrategyController - `0x6e19B0D99bE87B511fe1612e8097D32912348AEF`
 - RewardDistributor - `0x3064c7E6ff89998eb3Ad9768D23090db8f4C57a5`
 - MultiStakingRewards - `0x145191C725DB2ab84683333071A417E244736A9D`

### USDT Compound Strategy
- StrategyUSDTCompound - `0xfFe1CC3FaDBDbC4bC5ca85539e8e7327A46c7Ad0`
- Vault - `0xB954c52E3377E92c379F033326a1Df5797260692`

### Test Tokens
- Use Compound.finance on Kovan to get USDC, USDT from faucet for testing
- Compound Kovan addresses:
  - USDC: `0xb7a4F3E9097C08dA09517b5aB877F7a917224ede`
  - USDT: `0x07de306FF27a2B630B1141956844eB1552B956B5`
  - COMP: `0x61460874a7196d6a22D1eE4922473664b3E95270`
