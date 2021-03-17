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


### MAINNET FORK
 - ALDToken - `0x32d178C0e40306082759137342E12c2E275661F1`
 - Treasury - `0x5Bb7bCcc778a4d363C332BD099fecf3D1F04ad85`
 - DAO - `0xb06ED461C8e0A58CB45BC08a10f3fF24561A820a`
 - TokenDistributor - `0x90c922253B3CB02c65b01Aa8470E653537541b1E`
 - RewardDistributor - `0x1AE62273ca320DD11924B9866fbb5942c6D990BA`
 - Controller - `0xFf1e5703708F7cF5f50071b97295E0b361fCcA0F`
 - WrappedALDToken - `0x01E1BB8fB2F8a996f715e48D18a5181bD677702B`
 - TokenMaster - `0x62107e0bA95a2A90a1C98C94a957d3e78283c704`
 - MultiStakingRewards - `0x9dba3d8eD418653b364E31c10606dbBC8dc2040B`

#### Strategies
- VaultUSDTCompound - `0xF811258C54e25cD3129fD3Df66EE0b072C664211`
- StrategyUSDTCompound - `0x5f8Cf004d06fF3900Eb8bb396049d84f352dB862`

- VaultCurveAave3Pool - `0x5d53Af8E8464859872187cE39d671A5306FD13fc`
- StrategyCurveAave3Pool - `0x227281227836a638929fa62FDB4FD1B700E1BCec`

- VaultCurveSETH - `0x7F2261a5655Ff3BEd45ff38854AAEe2b403E93f0`
- StrategyCurveSETH - `0xd4E549918e41B61659AC17216ddE4775552bAaA8`

- VaultCurveRenWBTC - `0xD503Dc3F3490627651C13a3c3822AE29D9862AC1`
- StrategyCurveRenWBTC - `0x00B7E69380816eBb9eB883EFcbAd88FA782Ad53F`
