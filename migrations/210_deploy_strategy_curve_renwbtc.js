// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyRenWBTC = artifacts.require('StrategyRenWBTC')
const VaultRenWBTC = artifacts.require('VaultRenWBTC')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyRenWBTC(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyRenWBTC(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyRenWBTC,
    controller.address
  )

  const vault = await VaultRenWBTC.deployed();
  const strategy = await StrategyRenWBTC.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
