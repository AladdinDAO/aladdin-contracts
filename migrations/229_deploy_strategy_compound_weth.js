// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCompoundWETH = artifacts.require('StrategyCompoundWETH')
const VaultCompoundWETH = artifacts.require('VaultCompoundWETH')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCompoundWETH(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCompoundWETH(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCompoundWETH,
    controller.address
  )

  const vault = await VaultCompoundWETH.deployed();
  const strategy = await StrategyCompoundWETH.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
