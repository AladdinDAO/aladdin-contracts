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
- StrategyCompoundUSDT - `0x8397DF73E3e9381dFFbCBEb513AE73cfF5474C34`

#### Test Tokens
- Use Compound.finance on Kovan to get USDC, USDT from faucet for testing
- Compound Kovan addresses:
  - USDC: `0xb7a4F3E9097C08dA09517b5aB877F7a917224ede`
  - USDT: `0x07de306FF27a2B630B1141956844eB1552B956B5`
  - COMP: `0x61460874a7196d6a22D1eE4922473664b3E95270`


### MAINNET FORK
 - ALDToken - `0x24259EbbE91fD9c3868EDc29273a5c4FB14ED1BD`
 - Treasury - `0xCB08C9F20b9daaAf3151E5b08E0a36E8212D4365`
 - DAO - `0xDEc956C90228B771A7b7282d378684859f257349`
 - TokenDistributor - `0x08AAb01a572EDe034D110C4262f10Bd472CE67Aa`
 - RewardDistributor - `0xc0bfc4A308722318a4AaC3B2eD86bd06bA62B115`
 - Controller - `0x2c8039bD28388765E1934B364Cd2284faef6BA8A`
 - WrappedALDToken - `0x815f7Bd03CB8536E3Bdd1be887d1FE5273C8842C`
 - TokenMaster - `0xdb8EA75524a484b028e7796E004cDd836570F479`
 - MultiStakingRewards - `0xaEdf502f3f4e3EB1229fAB948D7479BB345F4Af9`

#### Strategies
- VaultCompoundUSDT - `0xf73c7926E494aB20f7c549014D6988178D21b0e0`
- StrategyCompoundUSDT - `0x533D55cf99811eCfaf47ab87E1C0024a09ce563a`

- VaultCurveAave3Pool - `0xe596E4329d39f181E509dD9E44F53E229bD0Ec3C`
- StrategyCurveAave3Pool - `0x626A02da96Bb3e6afD348FA11Ac874E280fE1752`

- VaultCurveSETH - `0x701AE8ba9CE0EB92d62F75A23EF51d7ED767692C`
- StrategyCurveSETH - `0xB0D0F14D76e0f7fb7c3293437852c5C7159036f8`

- VaultCurveRenWBTC - `0x9774964286f5fC19267A8f15B6A97032b83172b0`
- StrategyCurveRenWBTC - `0x012D3DB56B62D4CE6CEd839fe7AE987fd5Fb2C1D`

- VaultSushiETHUSDC - `0x2872659ef68AEc49d08b60C1FCBcc2612F1CD9a6`
- StrategySushiETHUSDC - `0xCBc4d52285B41A9a44356692d1C172495e0De44a`

- VaultSushiETHUSDT - `0x200615aEB1FC56e5F5339F39DB7263a6eC8aB99A`
- StrategySushiETHUSDT - `0x23Cf72F6be67026d4AFdec916a7DFfDD240095F7`

- VaultSushiETHDAI - `0x7A3DD358EeCd5725a8dE702ce3F437b1E79DB0Cc`
- StrategySushiETHDAI - `0x56d596fd792FD45B25a915DfFC7C1724695c7554`

- VaultSushiETHWBTC - `0xF259874288b328F4B5F8e80F8bC2481D13e4a7d8`
- StrategySushiETHWBTC - `0x50d84344cCeBe931f57327c21b69f571485cb1B6`

- VaultCompoundUSDC - `0x9f9FcC46aE72e5a32d3624edC25E1296dA6d7E10`
- StrategyCompoundUSDC - `0x8e011E083911e278c03e915a9bFE3f0E008e42f6`

- VaultCompoundDAI - `0xa39118b16BEdF6E699934d3bF2B9FD6ffA25552A`
- StrategyCompoundDAI - `0xDe7347F9e875D49feeF2d05F8dE669D46F9eA196`

- VaultCompoundWBTC - `0x502ce4A3b569cEecb5c40960279D90E796270D1C`
- StrategyCompoundWBTC - `0x0476fa4080FDBDa1E0210Bff05636ECE1906227A`

- VaultCurve3Pool - `0xF855066058cC20990720520b94371F9745D0DB74`
- StrategyCurve3Pool - `0x764dC083EF81Bc108499E7c9aA5c6F1C5bA87b24`

- VaultCurveHBTC - `0x64e71707d707719D675c69bD2E2014678D26baD3`
- StrategyCurveHBTC - `0x18C5eEf648984D3CFEb9DFC751A1587f2baB1DB5`
