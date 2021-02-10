// ============ Contracts ============

const StrategyController = artifacts.require('StrategyController')
const StrategyUSDCCompound = artifacts.require('StrategyUSDCCompound')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyUSDCCompound(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyUSDCCompound(deployer, network) {
  const controller = await StrategyController.deployed();

  await deployer.deploy(
    StrategyUSDCCompound,
    controller.address
  )
}
