// ============ Contracts ============

const StrategyController = artifacts.require('StrategyController')
const StrategyUSDTCompound = artifacts.require('StrategyUSDTCompound')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyUSDTCompound(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyUSDTCompound(deployer, network) {
  const controller = await StrategyController.deployed();

  await deployer.deploy(
    StrategyUSDTCompound,
    controller.address
  )
}
