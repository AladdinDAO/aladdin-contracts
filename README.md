# AladdinDAO

## Contract Overview

![Overview](/diagram.png)

### Token
Contracts for the ALD token and its distribution.

### Farm
Contracts for yearn style strategies. Strategies does not auto sell rewards for underlying, but allow users to claim them instead

### Reward
Staking reward contracts for ALD token.

### DAO
Contracts for funding and treasury

## Deployments

### KOVAN
 - ALDToken - `0xf3E38d0278a6b8Af7264e5B5123dfd6E34695E9c`
 - Treasury - `0x4007166E0c133D5e8a13A1D033A0bb13A96E8454`
 - DAO - `0x4D8ddf44296A881fd5655B75A6c093DD7a611438`
 - TokenDistributor - `0xc2B0cE37e705af81f0ed09FB09E99F9CBD268f4A`
 - RewardDistributor - `0x9d0bF5E0e9b458630C1D2bdbbFFCC72CB3E063d7`
 - Controller - `0xa2CB711cEA13403dF526A25a35B7A4F734ADDe6C`
 - WrappedALDToken - `0x445845b76e1EB54b52DC64E96e638bD40BCeB305`
 - TokenMaster - `0x21fe7F05dB5BbBC5957dC360c94da997B544d9fe`
 - MultiStakingRewards - `0xC0Cf995128F09155539D3B4D67FDF1Bc38EeCFa5`

### USDT Compound Strategy
- StrategyUSDTCompound - `0x2441816ec5388f57E4Fc3c4002AaA32c4278AC5A`
- Vault - `0x565A0A5E67ba4603Ab70d3a97f51E2195C6A1df3`

### Test Tokens
- Use Compound.finance on Kovan to get USDC, USDT from faucet for testing
- Compound Kovan addresses:
  - USDC: `0xb7a4F3E9097C08dA09517b5aB877F7a917224ede`
  - USDT: `0x07de306FF27a2B630B1141956844eB1552B956B5`
  - COMP: `0x61460874a7196d6a22D1eE4922473664b3E95270`
