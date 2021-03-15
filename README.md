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
 - ALDToken - `0x16a66452fE2a585A0918EBF93AdB5b301f834Cdd`
 - Treasury - `0x200ED48F6b7FE210Bb28883870450b24De4d7BBE`
 - DAO - `0xc8A2F9d5A315e2398290f0E201560C40a9Ea55Cd`
 - TokenDistributor - `0xCA78f50aD825faE75C534aec91DBBc618191F313`
 - RewardDistributor - `0x3AA8C324efCa6780bC26aFB5cA314b8f1BD71429`
 - Controller - `0x116C8Eb399f3284C9621fF2700Adbd1c6B0A0457`
 - WrappedALDToken - `0x656E49A294bBe7479bf42e3ad0d5705cE2C957da`
 - TokenMaster - `0x207311457b87285eC62fb9998f3A804ff707d2CF`
 - MultiStakingRewards - `0x6d650f037EdBe16AC21AAc37AB9Dd7c78d87a761`

#### Strategies
- VaultUSDTCompound - `0x44Be0343E39c7cf4EA3Be490861e09956267E1f2`
- StrategyUSDTCompound - `0xC93afB8E8c6A7b2bc5C54A6ea9CDA5D13f007e1c`

- VaultCurveAave3Pool - `0x884AF59Dcc11bC8Bad47cb97C1C45ab8fF97D8ae`
- StrategyCurveAave3Pool - `0x9a0f9f3F1F8811AE0F6D5B0504CDfDd3Bc0EC7Aa`

- VaultCurveSETH - `0xCc2Da884A1AD03D7916Feb6DB9721Ff5578f6eA0`
- StrategyCurveSETH - `0xB745FAD3eC94Cf8D09212b45A831743C55a41710`

- VaultCurveRenWBTC - `0xCB08C9F20b9daaAf3151E5b08E0a36E8212D4365`
- StrategyCurveRenWBTC - `0xDEc956C90228B771A7b7282d378684859f257349`
