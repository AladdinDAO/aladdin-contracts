// ============ Contracts ============

const StrategyController = artifacts.require('StrategyController')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyController(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyController(deployer, network) {
  await deployer.deploy(StrategyController)
}
