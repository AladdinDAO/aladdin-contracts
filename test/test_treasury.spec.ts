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

describe('treasury', () => {
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

    it('test takeOut token', async () => {
        const tokenAmount = expandTo18Decimals(10000)
        await usdt.mint(treasury.address, tokenAmount)

        await expect(treasury.connect(other).takeOut(usdt.address, other.address, tokenAmount)).to.be.reverted

        await expect(
            treasury.takeOut(usdt.address, wallet.address, tokenAmount)
        )
        .to.emit(usdt, 'Transfer')
        .withArgs(treasury.address, wallet.address, tokenAmount)
    })


    it('test takeOut eth', async () => {
        await mineBlock(provider, (await provider.getBlock('latest')).timestamp + 3600)
        await wallet.sendTransaction({to: treasury.address, value: 10})

        await expect(treasury.connect(other).takeOutETH(other.address, 10)).to.be.revertedWith('!gov')
    })

    describe('permission', () => {
        it('set gov', async () => {
            await expect(treasury.connect(other).setGov(other.address)).to.be.revertedWith('!gov')
            await treasury.setGov(other.address)
            expect(await treasury.governance()).to.eq(other.address)
        })

    })
})
