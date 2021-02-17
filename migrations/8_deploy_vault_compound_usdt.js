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
    "0x07de306FF27a2B630B1141956844eB1552B956B5", // usdt
    "0x61460874a7196d6a22D1eE4922473664b3E95270", // comp
    controller.address,
    tokenMaster.address
  )
}
