// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCompoundUSDT = artifacts.require('StrategyCompoundUSDT')
const VaultCompoundUSDT = artifacts.require('VaultCompoundUSDT')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCompoundUSDT(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCompoundUSDT(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCompoundUSDT,
    controller.address
  )

  const vault = await VaultCompoundUSDT.deployed();
  const strategy = await StrategyCompoundUSDT.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
