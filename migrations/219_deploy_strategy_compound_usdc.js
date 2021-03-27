// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCompoundUSDC = artifacts.require('StrategyCompoundUSDC')
const VaultCompoundUSDC = artifacts.require('VaultCompoundUSDC')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCompoundUSDC(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCompoundUSDC(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCompoundUSDC,
    controller.address
  )

  const vault = await VaultCompoundUSDC.deployed();
  const strategy = await StrategyCompoundUSDC.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
