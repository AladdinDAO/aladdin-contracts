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
 - ALDToken - `0x30403605E199ae6C7650E6eA0Ff3A883A240E17f`
 - Treasury - `0xBa1cDf908976a2e3D7C5081279914cFA0b444463`
 - DAO - `0x8262edb4b9074f1e5b05B07F5E4E97717c284547`
 - TokenDistributor - `0x30d6f4afa4606B0Cc60f62aEE87d8AdFC0536226`
 - RewardDistributor - `0xed2C5Baf4048AEB83ff7fc72b9e9A347017C7C34`
 - Controller - `0x6aB2df271F1747CCAc85AD649a8eD178D058B749`
 - WrappedALDToken - `0x79B99F22d8d8DCeAD69d2acA90AEc9EB89ACC060`
 - TokenMaster - `0xD14fFAb5169598b9FA1A0a1e8657572779ed7af7`
 - MultiStakingRewards - `0x8E49Ad6c8F4e2E348A120391D11B745a15f09995`

#### USDT Compound Strategy
- Vault - `0x1411a1a5B73C057Ed7B61246A17E892c11339f3D`
- StrategyUSDTCompound - `0x8397DF73E3e9381dFFbCBEb513AE73cfF5474C34`

#### Test Tokens
- Use Compound.finance on Kovan to get USDC, USDT from faucet for testing
- Compound Kovan addresses:
  - USDC: `0xb7a4F3E9097C08dA09517b5aB877F7a917224ede`
  - USDT: `0x07de306FF27a2B630B1141956844eB1552B956B5`
  - COMP: `0x61460874a7196d6a22D1eE4922473664b3E95270`
