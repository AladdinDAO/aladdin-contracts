// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCompoundDAI = artifacts.require('StrategyCompoundDAI')
const VaultCompoundDAI = artifacts.require('VaultCompoundDAI')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCompoundDAI(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCompoundDAI(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCompoundDAI,
    controller.address
  )

  const vault = await VaultCompoundDAI.deployed();
  const strategy = await StrategyCompoundDAI.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
