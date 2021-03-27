// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCompoundWBTC = artifacts.require('StrategyCompoundWBTC')
const VaultCompoundWBTC = artifacts.require('VaultCompoundWBTC')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCompoundWBTC(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCompoundWBTC(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCompoundWBTC,
    controller.address
  )

  const vault = await VaultCompoundWBTC.deployed();
  const strategy = await StrategyCompoundWBTC.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
