import { Wallet, Contract } from 'ethers'
import { Web3Provider } from 'ethers/providers'
import { deployContract } from 'ethereum-waffle'
import { expandTo18Decimals } from './utilities'

import ERC20 from '../../build/contracts/ERC20.json'
import ALDToken from '../../build/contracts/ALDToken.json'
import DAO from '../../build/contracts/DAO.json'
import Treasury from '../../build/contracts/Treasury.json'
import TokenDistributor from '../../build/contracts/TokenDistributor.json'
import RewardDistributor from '../../build/contracts/RewardDistributor.json'
import Controller from '../../build/contracts/Controller.json'
import WrappedERC20 from '../../build/contracts/WrappedERC20.json'
import Vault from '../../build/contracts/Vault.json'
import TokenMaster from '../../build/contracts/TokenMaster.json'
import StrategyUSDTCompound from '../../build/contracts/StrategyUSDTCompound.json'
import MultiStakingRewards from '../../build/contracts/MultiStakingRewards.json'



const overrides = {
    gasLimit: 9999999
}


interface Fixture {
    ald: Contract
    treasury: Contract
    dao: Contract
    tokenDistributor: Contract
    rewardDistributor: Contract
    controller: Contract
    wrappedAld: Contract
    tokenMaster: Contract
    vault: Contract
    strategyUSDTCompound: Contract
    multiStakingRewards: Contract
    usdt: Contract
    comp: Contract
}


export async function getFixture(provider: Web3Provider, [wallet]: Wallet[]): Promise<Fixture> {
    // deploy tokens
    console.log(`using wallet `, wallet.address)
    const usdt = await deployContract(wallet, ERC20, ["usdt", "USDT"])
    const comp = await deployContract(wallet, ERC20, ["compound", "COMP"])
    const ald = await deployContract(wallet, ALDToken)
    const treasury = await deployContract(wallet, Treasury)
    const dao = await deployContract(wallet, DAO, [usdt.address, "10", "2", [wallet.address]])
    const tokenDistributor = await deployContract(wallet, TokenDistributor,  [[wallet.address]])
    const rewardDistributor = await deployContract(wallet, RewardDistributor,  [[wallet.address]])
    const controller = await deployContract(wallet, Controller)
    const wrappedAld = await deployContract(wallet, WrappedERC20, [ald.address,  "Wrapped Aladdin DAO Token", "wALD"])
    const tokenMaster = await deployContract(wallet, TokenMaster, [ald.address,  tokenDistributor.address])

    const vault = await deployContract(wallet, Vault, [usdt.address,  comp.address, controller.address, tokenMaster.address], overrides)
    const strategyUSDTCompound = await deployContract(wallet, StrategyUSDTCompound, [controller.address],overrides )
    const multiStakingRewards = await deployContract(wallet, MultiStakingRewards, [ald.address, wrappedAld.address, rewardDistributor.address], overrides)

 
    return {
        ald,
        treasury,
        dao,
        tokenDistributor,
        rewardDistributor,
        controller,
        wrappedAld,
        tokenMaster,
        vault,
        strategyUSDTCompound,
        multiStakingRewards,
        usdt,
        comp
    }
}