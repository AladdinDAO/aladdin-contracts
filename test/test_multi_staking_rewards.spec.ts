import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { MaxUint256 } from 'ethers/constants'
import { BigNumber, bigNumberify, defaultAbiCoder, formatEther } from 'ethers/utils'
import { solidity, MockProvider, createFixtureLoader, deployContract } from 'ethereum-waffle'

import { expandTo18Decimals, mineBlock } from './shared/utilities'
import { getFixture } from './shared/fixtures'


chai.use(solidity)

const overrides = {
    gasLimit: 9999999,
    gasPrice: 0
}

describe('multi staking rewards', () => {
    const provider = new MockProvider({
        hardfork: 'istanbul',
        mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
        gasLimit: 9999999
    })
    const hour = 3600
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

    it('test stake & withdraw', async () => {
        const mintAmount = 10000
        await ald.setMinter(wallet.address, true)
        await ald.mint(wallet.address, expandTo18Decimals(mintAmount * 2)) // deployer
        await ald.approve(wrappedAld.address, expandTo18Decimals(mintAmount))
        await wrappedAld.wrap(wallet.address, expandTo18Decimals(mintAmount))
        await wrappedAld.transfer(rewardDistributor.address, expandTo18Decimals(mintAmount))
        await multiStakingRewards.addRewardPool(wrappedAld.address, 24 * hour)
        await rewardDistributor.distributeRewards([multiStakingRewards.address], [wrappedAld.address], [expandTo18Decimals(mintAmount)])
        await ald.approve(multiStakingRewards.address, expandTo18Decimals(mintAmount))
        await multiStakingRewards.stake(expandTo18Decimals(mintAmount))
        await mineBlock(provider, (await provider.getBlock('latest')).timestamp + 1 * hour)
        await expect(
            multiStakingRewards.withdraw(expandTo18Decimals(mintAmount))
        )
        .to.emit(multiStakingRewards, 'Withdrawn')
        .withArgs(wallet.address, expandTo18Decimals(mintAmount))
    })


    it('test exit', async () => {
        const mintAmount = 10000
        await ald.setMinter(wallet.address, true)
        await ald.mint(wallet.address, expandTo18Decimals(mintAmount * 2)) // deployer
        await ald.approve(wrappedAld.address, expandTo18Decimals(mintAmount))
        await wrappedAld.wrap(wallet.address, expandTo18Decimals(mintAmount))
        await wrappedAld.transfer(rewardDistributor.address, expandTo18Decimals(mintAmount))
        await multiStakingRewards.addRewardPool(wrappedAld.address, 24 * hour)
        await rewardDistributor.distributeRewards([multiStakingRewards.address], [wrappedAld.address], [expandTo18Decimals(mintAmount)])

        await ald.approve(multiStakingRewards.address, expandTo18Decimals(mintAmount))
        await multiStakingRewards.stake(expandTo18Decimals(mintAmount))
        await mineBlock(provider, (await provider.getBlock('latest')).timestamp + 1 * hour)
        await expect(
            multiStakingRewards.exit()
        ).to.emit(multiStakingRewards, 'RewardPaid')
    })


    describe('gov permission', () => {
        it('reward pool', async () => {
            await expect(multiStakingRewards.connect(other).addRewardPool(wrappedAld.address, 24 * 3600)).to.be.revertedWith('!governance')
            await multiStakingRewards.addRewardPool(wrappedAld.address, 24 * hour)
        })

        it('set inactivateRewardPool', async () => {
            await multiStakingRewards.addRewardPool(wrappedAld.address, 24 * hour)
            await expect(multiStakingRewards.connect(other).inactivateRewardPool(wrappedAld.address)).to.be.revertedWith('!governance')
            const beforePoolLength = await  multiStakingRewards.activeRewardPoolsLength()
            await multiStakingRewards.inactivateRewardPool(wrappedAld.address)
            const afterPoolLength = await  multiStakingRewards.activeRewardPoolsLength()
            expect(beforePoolLength -1 ).to.eq(afterPoolLength)
        })


        it('set inactivateRewardPool by index', async () => {
            await expect(multiStakingRewards.connect(other).inactivateRewardPool(wrappedAld.address)).to.be.revertedWith('!governance')
            await multiStakingRewards.addRewardPool(wrappedAld.address, 24 * hour)
            const beforePoolLength = await  multiStakingRewards.activeRewardPoolsLength()
            await multiStakingRewards.inactivateRewardPoolByIndex(0)
            const afterPoolLength = await  multiStakingRewards.activeRewardPoolsLength()
            expect(beforePoolLength -1 ).to.eq(afterPoolLength)
        })


        it('rescue', async () => {
            await multiStakingRewards.addRewardPool(wrappedAld.address, 24 * hour)
            await expect(multiStakingRewards.connect(other).rescue(wrappedAld.address)).to.be.revertedWith('!governance')
            await multiStakingRewards.inactivateRewardPoolByIndex(0)
            await multiStakingRewards.rescue(wrappedAld.address)
        })


        it('set gov', async () => {
            await expect(multiStakingRewards.connect(other).setGov(other.address)).to.be.revertedWith('!governance')
            await multiStakingRewards.setGov(other.address)
            expect(await multiStakingRewards.governance()).to.eq(other.address)
        })
    })
})
