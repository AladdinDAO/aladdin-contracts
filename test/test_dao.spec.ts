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

    it('test deposit', async () => {
        await usdt.mint(wallet.address, expandTo18Decimals(10000))
        await usdt.approve(dao.address, expandTo18Decimals(10000))
        await expect(
            dao.fund(1)
        )
        .to.emit(dao, 'Transfer')
        .withArgs("0x0000000000000000000000000000000000000000", wallet.address, 1)
    })

    it('test withdraw', async () => {
        await usdt.mint(wallet.address, expandTo18Decimals(10000))
        await usdt.approve(dao.address, expandTo18Decimals(10000))
        await dao.fund(1)
        await expect(
            dao.takeOut(usdt.address, wallet.address, expandTo18Decimals(1))
        )
        .to.emit(usdt, 'Transfer')
        .withArgs(dao.address, wallet.address, expandTo18Decimals(1))

        expect(await usdt.balanceOf(wallet.address)).to.eq(expandTo18Decimals(10000))
    })

    it('remove whitelist', async () => {
        await dao.removeFromWhitelist(wallet.address)
        expect(await dao.isWhitelisted(wallet.address)).to.eq(false)
    })
})
