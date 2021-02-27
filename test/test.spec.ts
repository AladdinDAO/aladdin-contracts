import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { MaxUint256 } from 'ethers/constants'
import { BigNumber, bigNumberify, defaultAbiCoder, formatEther } from 'ethers/utils'
import { solidity, MockProvider, createFixtureLoader, deployContract } from 'ethereum-waffle'

import { expandTo18Decimals } from './shared/utilities'
import { getFixture } from './shared/fixtures'


chai.use(solidity)

const overrides = {
    gasLimit: 9999999,
    gasPrice: 0
}

describe('unitTest', () => {
    const provider = new MockProvider({
        hardfork: 'istanbul',
        mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
        gasLimit: 9999999
    })
    const [wallet] = provider.getWallets()
    const loadFixture = createFixtureLoader(provider, [wallet])
    let ald: Contract
    let treasury: Contract
    let dao: Contract
    let tokenDistributor: Contract
    let rewardDistributor: Contract
    let controller: Contract
    let wrappedAld: Contract
    let tokenMaster: Contract
    let vault: Contract
    let strategyUSDTCompound: Contract
    let multiStakingRewards: Contract
    let usdt: Contract
    let comp: Contract
    beforeEach(async function () {
        const fixture = await loadFixture(getFixture)
        ald = fixture.ald
        treasury = fixture.treasury
        dao = fixture.dao
        tokenDistributor = fixture.tokenDistributor
        rewardDistributor = fixture.rewardDistributor
        controller = fixture.controller
        wrappedAld = fixture.wrappedAld
        tokenMaster = fixture.tokenMaster
        vault = fixture.vault
        strategyUSDTCompound = fixture.strategyUSDTCompound
        multiStakingRewards = fixture.multiStakingRewards
        usdt = fixture.usdt
        comp = fixture.comp
    })

    it('initSetup', async () => {
        let gov = await ald.governance()
        console.log(`gov`, gov)
        await ald.setMinter(tokenMaster.address, true)
        await controller.setStrategy(vault.address, strategyUSDTCompound.address)
        await tokenMaster.add("100", vault.address, true)
        // add deployer as minter and mint
        await ald.setMinter(wallet.address, true) // deployer
        const oneMillion = "1000000000000000000000000"
        await ald.mint(wallet.address, oneMillion) // deployer
        console.log('minted ald')
        // add to dao whitelist
        await dao.addToWhitelist("0x561ADa4B0243F1d83dF80D1653E9F76E84128b0b") // gao
        console.log('added addresses to dao whitelist')
        // send rewards to multistakingrewards
        await multiStakingRewards.setRewardsDistribution(wallet.address) // deployer
        await multiStakingRewards.addRewardPool(wrappedAld.address, 604800) // 7 days
        console.log('added wALD reward pool to staking rewards')
        await ald.approve(wrappedAld.address, oneMillion)
        await wrappedAld.wrap(multiStakingRewards.address, oneMillion)
        console.log('wrapped ALD and sent to staking rewards')
        await multiStakingRewards.notifyRewardAmount(wrappedAld.address, oneMillion)
        console.log('notified staking rewards')
    })
})
