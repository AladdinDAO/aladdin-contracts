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
 - ALDToken - `0x4d8C9A143Ece4B5735284bc7C2c1cf5188Ff8253`
 - Treasury - `0x09de1576850FbFCEa9FC3F62332fa95f21131D25`
 - DAO - `0x373E03f09ea63c535CBbc0Eb1F45c8dB9ea10979`
 - TokenDistributor - `0x322111e37d92a3A245DeBD6FF94eA234723698Ef`
 - RewardDistributor - `0x40ec0aE50918e7CB34905008e85F074f4BEB54A1`
 - Controller - `0x235dA10e04312791D775C824417568da017b913e`
 - WrappedALDToken - `0xFB5038878B816def4904339ebaDf66Df2c46ef06`
 - TokenMaster - `0xd14f970148C92b0D2ED8F3212FB9841474121A26`
 - MultiStakingRewards (Option Rewards) - `0x17324dEdF1DcaA2582F66cff520ddEE7162D3E90`
 - MultiStakingRewards (DAO Rewards) - `0x3b494E0326BC933595eF3a9207F69316945fD34d`
 - ALD_ETH_UNISWAP_LP - `0x5cA9207627B9eB5f6107Aa8c45367A52498593E3`
 - ALD_USDC_UNISWAP_LP - `0x3d6BE6d79235feA68262609B527bfb0704b29Bc4`
 - ALDPlus - `0x20aA6125b9FB596cc33AA9290046274Daa3e7BbB`

#### Strategies
- VaultCompoundUSDT - `0xC5C1Dcd04648Eda6457b32722DF504B2c382b2d2`
- StrategyCompoundUSDT - `0x0DB9d0e32fD74FE2E9c5906e5e4509e739b20b29`

- VaultCurveAave3Pool - `0x1c01eeFA933Ac14E93aD42f2263ACCA9868C3619`
- StrategyCurveAave3Pool - `0x1176988461bCdfA247Ef8c54c4c27C5De7c7781d`

- VaultCurveSETH - `0x1ceCeBa3Dc2a2F1c2Cc44a2076F6048060147f41`
- StrategyCurveSETH - `0x0c50e48385Ebe4f1C74B1ad5Bcb4Ab998aA17DFf`

- VaultCurveRenWBTC - `0x11Ca86160828E5B79F3101b3129A1f3634842Fcc`
- StrategyCurveRenWBTC - `0x8c41f86Fe53975823597E6A7D9a71ae7dF848E2E`

- VaultSushiETHUSDC - `0xb621E36E77Cc39D4bc3877f98906cfBcEe902754`
- StrategySushiETHUSDC - `0xD0f5c912E021D000AF8c3302058881B2bdB98289`

- VaultSushiETHUSDT - `0x1cD66685881a89cfdE4AA0815801AEB10618b16F`
- StrategySushiETHUSDT - `0xB0A69b6546213863108600DbbD1f9EF5cFE137a2`

- VaultSushiETHDAI - `0xAa001C86Abae6a1757746485fa7159d0F14b5e1f`
- StrategySushiETHDAI - `0xDF09B67Ad4785956776e46b87c35De8952270aF3`

- VaultSushiETHWBTC - `0x28C7ce6725770EcBd5DEc9862540E3f15B2199B1`
- StrategySushiETHWBTC - `0x91a987A32b777Fc205B9b1D63Eee4312D1962E49`

- VaultCompoundUSDC - `0x702303688263a998a3F8449D498194B66fd1B811`
- StrategyCompoundUSDC - `0xbDEE70F8b5aa4a6F32B2acd0C293f937c7c4CBfc`

- VaultCompoundDAI - `0xf0947680B611Ee735f03E8F546fC692941183702`
- StrategyCompoundDAI - `0xdcF1421e8DD51842cde1b9450298f6A3F5b798F8`

- VaultCompoundWBTC - `0x9984fFF1D390D1a31865C04541a8C1DD5F0Bee4b`
- StrategyCompoundWBTC - `0xcF714f5eCb9f620431Bfd774EE6D264CfD18420d`

- VaultCurve3Pool - `0x2FE479876e2E3655233710e949a59F0d4038aBaE`
- StrategyCurve3Pool - `0x388d62685CC9bD1ec70e4828Ac759eb797B54Ec4`

- VaultCurveHBTC - `0x6efe060bfF1AC94B16d1Ca1E6b330E91078E3168`
- StrategyCurveHBTC - `0x92c10Efe4dA0c6ce686c90b64B92dcB5256E726e`

- VaultCompoundWETH - `0x83dCd2b79e0558B4A32Ecb7338716E5bFe0fB86d`
- StrategyCompoundWETH - `0x2844526B539d3Da3e4368F09D6a7578260296e47`
