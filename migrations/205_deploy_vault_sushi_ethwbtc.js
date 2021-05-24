// ============ Contracts ============

const Controller = artifacts.require('Controller')
const TokenMaster = artifacts.require('TokenMaster')
const VaultSushiETHWBTC = artifacts.require('VaultSushiETHWBTC')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployVaultSushiETHWBTC(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployVaultSushiETHWBTC(deployer, network) {
  const controller = await Controller.deployed();
  const tokenMaster = await TokenMaster.deployed();

  await deployer.deploy(
    VaultSushiETHWBTC,
    controller.address,
    tokenMaster.address
  )
}
