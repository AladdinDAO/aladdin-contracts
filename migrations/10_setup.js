// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyUSDTCompound = artifacts.require('StrategyUSDTCompound')
const Vault = artifacts.require('Vault')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    setupContracts(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function setupContracts(deployer, network) {
  const vault = await Vault.deployed();
  const strategy = await StrategyUSDTCompound.deployed()
  const controller = await Controller.deployed();
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
