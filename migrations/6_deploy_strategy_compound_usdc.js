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
    controller.address,
    "0xb7a4F3E9097C08dA09517b5aB877F7a917224ede", // usdc
    "0x61460874a7196d6a22D1eE4922473664b3E95270" // comp
  )
}
