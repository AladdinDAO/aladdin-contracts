# AladdinDAO
A community driven yield farming DAO.

## Build

1. `npm install`
2. `npx truffle compile`

## Test
`npm run test`

## Contract Overview

![Overview](/diagram.png)

Contracts are broken down and categorized into directories, each representing module of the system.

### Token
Contracts for ALD token and distribution logic using a modified version of SushiMaster.

### Farm
Contracts for yearn style yield farming system.

### Reward
Standard Synthetix style staking reward contracts with modification for allowing multiple reward tokens.

### DAO
Contracts for DAO and treasury

## Deployments

### KOVAN
 - ALDToken - `0x17f4f5f5D4D0eebA80B42F941DC8Fdd4d0afa8d2`
 - Treasury - `0xaEA5A58a984cA0a01909e7f0cFa9383870e0Ef24`
 - DAO - `0x7f51ca06a9B2ba03A079092E4f0c39900C0971EB`
 - TokenDistributor - `0x0C5ddF84f907f15b2245868cEb52c2193EFC4899`
 - RewardDistributor - `0xB4DEd9DBB6aeE54a2a471ED776D34ef08c753d54`
 - Controller - `0x9FeF06a50c46394fb3044CEbb6eA715cf37D4D00`
 - WrappedALDToken - `0x82D5c2d1cd2CEB96191Ef637A44D2e5b45e89ae7`
 - TokenMaster - `0x716dd67D792cCd0f4D96512c0CFca9e09b7eB212`
 - MultiStakingRewards - `0x8B0DD44c3De67A9cC3855CA4de6402d7b3A5Ce46`

#### USDT Compound Strategy
- Vault - `0x531da358B99217d1Cc062B651e1CF8338A1B6060`
- StrategyUSDTCompound - `0x3f809E5eDC139ebF05bEDE72db7b7D0d8dC5d96c`

#### Test Tokens
- Use Compound.finance on Kovan to get USDC, USDT from faucet for testing
- Compound Kovan addresses:
  - USDC: `0xb7a4F3E9097C08dA09517b5aB877F7a917224ede`
  - USDT: `0x07de306FF27a2B630B1141956844eB1552B956B5`
  - COMP: `0x61460874a7196d6a22D1eE4922473664b3E95270`

### Mainnet Fork
 - ALDToken - `0xD0277B6b3430f360C80abd64214138545740B3Ba`
 - Treasury - `0xc200493dF8A0a4A7F67a0d9d7BB914BE41368122`
 - DAO - `0xEb08449660d8597bb40373c0FeEFB3Db4Ecb4447`
 - TokenDistributor - `0xFD2db572Ee7B6fBe9640CFE6f301Ed762C065717`
 - RewardDistributor - `0x0a535A036edcd53aC2FBd29023d85091cCf7075a`
 - Controller - `0x338Fe3216579E1137f3e49232C20E217Ac1Ac916`
 - WrappedALDToken - `0xD27bEf63De0A22EEF2f032Ab584c4Df115bA0b58`
 - TokenMaster - `0x8eB7dA86804A41a461BAa2f615fDc3726af536BC`
 - MultiStakingRewards - `0x14289943B066412bD9105C13e5F128a867BdfBF3`

#### USDT Compound Strategy
- Vault - `0x01E1BB8fB2F8a996f715e48D18a5181bD677702B`
- StrategyUSDTCompound - `0x62107e0bA95a2A90a1C98C94a957d3e78283c704`
