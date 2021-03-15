// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyUSDTCompound = artifacts.require('StrategyUSDTCompound')
const VaultUSDTCompound = artifacts.require('VaultUSDTCompound')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyUSDTCompound(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyUSDTCompound(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyUSDTCompound,
    controller.address
  )

  const vault = await VaultUSDTCompound.deployed();
  const strategy = await StrategyUSDTCompound.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
