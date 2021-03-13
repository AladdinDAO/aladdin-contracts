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

describe('reward distributor', () => {
    const provider = new MockProvider({
        hardfork: 'istanbul',
        mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
        gasLimit: 9999999
    })
    const [wallet, other] = provider.getWallets()
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

    it('test distributeTokens', async () => {
        let mintAmount = 10000
        await ald.setMinter(wallet.address, true)
        await ald.mint(wallet.address, expandTo18Decimals(mintAmount)) // deployer
        await ald.approve(wrappedAld.address, expandTo18Decimals(mintAmount))
        await wrappedAld.wrap(wallet.address, expandTo18Decimals(mintAmount))
        await wrappedAld.transfer(rewardDistributor.address, expandTo18Decimals(mintAmount))
        let balance = await wrappedAld.balanceOf(wallet.address)
        console.log(`balance ${balance}`)
        await multiStakingRewards.addRewardPool(wrappedAld.address, 4 * 3600)
        await expect(
            rewardDistributor.distributeRewards([multiStakingRewards.address], [wrappedAld.address], [expandTo18Decimals(mintAmount)])
        )
            .to.emit(rewardDistributor, 'DistributedReward')
            .withArgs(wallet.address, multiStakingRewards.address, wrappedAld.address, expandTo18Decimals(mintAmount))
    })



    describe('permission', () => {
        it('addFundManager', async () => {
            await expect(rewardDistributor.connect(other).addFundManager(other.address)).to.be.revertedWith('!governance')
            await rewardDistributor.addFundManager(other.address)
            expect(await rewardDistributor.fundManager(other.address)).to.eq(true)
        })


        it('remove FundManager', async () => {
            await rewardDistributor.addFundManager(other.address)
            await expect(rewardDistributor.connect(other).removeFundManager(other.address)).to.be.revertedWith('!governance')
            await rewardDistributor.removeFundManager(other.address)
            expect(await rewardDistributor.fundManager(other.address)).to.eq(false)
        })


        it('rescue', async () => {
            await ald.setMinter(wallet.address, true)
            await ald.mint(rewardDistributor.address, expandTo18Decimals(10000))
            await expect(rewardDistributor.connect(other).rescue(ald.address)).to.be.revertedWith('!governance')
            await expect(
                rewardDistributor.rescue(ald.address)
            ).to.emit(ald, 'Transfer')
            .withArgs(rewardDistributor.address, wallet.address, expandTo18Decimals(10000))
        })
    })
})
