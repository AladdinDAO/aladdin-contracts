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
 - ALDToken - `0x4F392e09303369A8976d4560057911e00b7E72E8`
 - Treasury - `0xF03905b850929a47A885dDf73b3A740120a519A3`
 - DAO - `0x9BDcC717A2FD947809c9ba34BCFaC6824Cf9Ca61`
 - TokenDistributor - `0x268902Dec507CfC0184c274c810F1FdCd5B4F1FD`
 - RewardDistributor - `0x718108eE7452798E214BEbEBa9E174284f353774`
 - Controller - `0x2412aa1d4F351aA73a14C4Eb7Be7F63b6336DA3c`
 - WrappedALDToken - `0x281517657B2D375De676c61aAC2ED98CE39e5De5`
 - TokenMaster - `0xC0c9Fd126084Bdd833D02F5E6882B72Cf85E6a39`
 - MultiStakingRewards - `0xaF6C602c1ce972793215AdCFa3123AeEDF58645d`
 - ALD_ETH_UNISWAP_LP - `0xdf5310ebEA7edDAE1Cd0CAf30cb51Ec8cd8EAcD5`
 - ALD_USDC_UNISWAP_LP - `0x985Cc83B39B059F67D78153d3CD59Bf588c0Fd84`

#### Strategies
- VaultCompoundUSDT - `0x2C6c85aCbEF54d808dE36B90A74dB6E84dBb4111`
- StrategyCompoundUSDT - `0x71eF938aF0Aea879459cb2DdD2EA9f40eF7EA430`

- VaultCurveAave3Pool - `0xccc34Eafa781a6c718EDcFD30a8aFDE04Abf3c7B`
- StrategyCurveAave3Pool - `0xd9aA4bAc83232FCDAd9B7Fe8430eae6c2eBDFa9a`

- VaultCurveSETH - `0x60Eb3024082190E16018428fb291484aA2D6D2F5`
- StrategyCurveSETH - `0xe0E238dDe89A1D58D2EB98CAC944E6f068b8A557`

- VaultCurveRenWBTC - `0x34ae95d2b8327fDC5eAd635F14EaaE2d3bF4BE9A`
- StrategyCurveRenWBTC - `0xCD0e616a63271384d75b00Ae3015ED45b042c694`

- VaultSushiETHUSDC - `0xacA7d91D8bf8e10451FD6cf17D009aDcD61dB17A`
- StrategySushiETHUSDC - `0xD33639C4Ad5eeA6884bC5FFbed15b2B28B72DB87`

- VaultSushiETHUSDT - `0xA1f543243556109b8D510eF0046aB24B841Bd027`
- StrategySushiETHUSDT - `0x27C5a284278675855121Fb443306eaD099bA9954`

- VaultSushiETHDAI - `0x391C46e008A94F61FC28D2a07f9A618c8B2C0eB9`
- StrategySushiETHDAI - `0x27a47e0313861AeC117Ac5cD84355374d2F8D1ac`

- VaultSushiETHWBTC - `0xEd647FDFd5B8393eD18ADA6927Cd905038Ce8362`
- StrategySushiETHWBTC - `0x0436C51334674130996909F8521b09a2Dc34e137`

- VaultCompoundUSDC - `0x7c08Ea9Cd18955CbA5FCeD3FF506315337d7Bc14`
- StrategyCompoundUSDC - `0x267c6f80f6F3B96c94F84C35A053303c5fE63963`

- VaultCompoundDAI - `0x26bAd6B3064c953e62366Cf09A0878Fc79a5B58c`
- StrategyCompoundDAI - `0x82B51775C9eB14314EF23E5e628a4b46610d5838`

- VaultCompoundWBTC - `0xAf9Df6a489e2Ca84A06E7d6bdC02a8e8237BB66b`
- StrategyCompoundWBTC - `0xBC85C568e0f44C446f7f27d8243c933943496D40`

- VaultCurve3Pool - `0x45b2e69d68F3896624f5351E9B86C30b206292e8`
- StrategyCurve3Pool - `0x2ef49e30c37Ea02CA4dc0eCae93d0d4e4C5Ee92a`

- VaultCurveHBTC - `0xBB7b2b1E97B50C0aD44cCFc5549C7f1273a9d08D`
- StrategyCurveHBTC - `0x8f9DD382af22bcDee65d6aE06df21464D5F75C44`

- VaultCompoundWETH - `0x81C6B3bb626320c4E5c134b7Bb4ABf59Ab6F3fdb`
- StrategyCompoundWETH - `0xd238FF9F5A3910e6e6F3a6f5A60B548b41538F2b`
