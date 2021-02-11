// ============ Contracts ============

const StrategyController = artifacts.require('StrategyController')
const StrategyUSDCCompound = artifacts.require('StrategyUSDCCompound')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    setupContracts(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function setupContracts(deployer, network) {
  const controller = await StrategyController.deployed();

  // Add strategy and vault to controller
  // Add vault to token master
}
