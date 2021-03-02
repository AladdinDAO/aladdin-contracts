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
 - ALDToken - `0x345762E8714Fb8AE09EFAA8448bBB723120b3C5C`
 - Treasury - `0xB47c7916cfF806C24ED3e24D9A3b2b1762d241ba`
 - DAO - `0x8F7e3D45316d3Ae606b2060e6b67Bea1bf4c4Cd5`
 - TokenDistributor - `0x69b9c902e43c3092676dB85165d40Fa75C6E0Ceb`
 - RewardDistributor - `0xDd14A849058c8Dccc7B75FC00e4730223684ab71`
 - Controller - `0x2D4fE7303D38eeF9a38cA771eE87e3c463e1d117`
 - WrappedALDToken - `0x367C525183724AA75500BE98d65Fe6Ff95DcFda9`
 - TokenMaster - `0x4B017C0E6Cde615915cA7B2aAA45E8220f98e8AA`
 - MultiStakingRewards - `0xf28F67Bb25c120142a556f31CEB7351bE2311425`

### USDT Compound Strategy
- Vault - `0x594219DDD8A7878De852c969BbCA3766b985F86b`
- StrategyUSDTCompound - `0x49eD7a5B15e9CB78BB494E6FD95611C63e960f40`

### Test Tokens
- Use Compound.finance on Kovan to get USDC, USDT from faucet for testing
- Compound Kovan addresses:
  - USDC: `0xb7a4F3E9097C08dA09517b5aB877F7a917224ede`
  - USDT: `0x07de306FF27a2B630B1141956844eB1552B956B5`
  - COMP: `0x61460874a7196d6a22D1eE4922473664b3E95270`
