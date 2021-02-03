// ============ Contracts ============

const StrategyController = artifacts.require('StrategyController')
const TokenMaster = artifacts.require('TokenMaster')
const Vault = artifacts.require('Vault')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployVault(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployVault(deployer, network) {
  const controller = await StrategyController.deployed();
  const tokenMaster = await TokenMaster.deployed();

  await deployer.deploy(
    Vault,
    "0xb7a4F3E9097C08dA09517b5aB877F7a917224ede", // usdc
    "0x61460874a7196d6a22D1eE4922473664b3E95270", // comp
    controller.address,
    tokenMaster.address
  )
}
