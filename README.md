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

### MAINNET FORK
 - ALDToken - `0xD0277B6b3430f360C80abd64214138545740B3Ba`
 - Treasury - `0x09A0B671Ea03D9b0ebca9D064A28bA0cF3B3fa0C`
 - DAO - `0x32d178C0e40306082759137342E12c2E275661F1`
 - ALDVote - `0x5Bb7bCcc778a4d363C332BD099fecf3D1F04ad85`
 - RewardDistributor - `0xb06ED461C8e0A58CB45BC08a10f3fF24561A820a`
 - RewardDistributorPermissioned - `0x90c922253B3CB02c65b01Aa8470E653537541b1E`
 - TokenDistributor - `0x1AE62273ca320DD11924B9866fbb5942c6D990BA`
 - WrappedALDToken - `0xFf1e5703708F7cF5f50071b97295E0b361fCcA0F`
 - MultiStakingRewards (Option Rewards) - `0x01E1BB8fB2F8a996f715e48D18a5181bD677702B`
 - MultiStakingRewards (DAO Rewards) - `0x9dba3d8eD418653b364E31c10606dbBC8dc2040B`
 - Wrapped DAO Token - `0x690cB9138935E3B0BbD7219161134DA3E8737a9f`
 - Controller - `0x0DD9993467528F344f371185be76c1388381703F`
 - TokenMaster - `0xAf1D12c6dE5a59b00A5fd7DeCD8b9137FC0DA880`
 - ALD_ETH_UNISWAP_LP - `0xdEc2C9319640947681A9ce87C19dE34753D20f74`
 - ALD_USDC_UNISWAP_LP - `0x39f378b41284dC386c38252b6B0cA30d14D6714F`
 - Keeper - `0xA1e121e8eE8d1C782C693E4A93Da9A9A406580Fe`

#### Strategies
- VaultCurveSETH - `0x227281227836a638929fa62FDB4FD1B700E1BCec`
- StrategyCurveSETH - `0x8B903bF58fbc53B06398DE366361334Ab503342a`

- VaultCurveRenWBTC - `0xd4E549918e41B61659AC17216ddE4775552bAaA8`
- StrategyCurveRenWBTC - `0xB3412b0253D15428Bc36ADC4c4b927B95431B553`

- VaultSushiETHWBTC - `0x16a66452fE2a585A0918EBF93AdB5b301f834Cdd`
- StrategySushiETHWBTC - `0x70026FdB01b85d3fb9297e888D11b60764C14A96`

- VaultCurve3Pool - `0xb258Ab139ae96E8c6Ca7f09646142b9c9c23e8B6`
- StrategyCurve3Pool - `0xe11C32D0248064B4190740765e2964c56A2e2cC5`

## Deployed Contracts
[Deployments](https://github.com/AladdinDAO/deployments)

## License
[MIT](LICENSE.txt)
