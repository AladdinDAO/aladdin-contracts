// ============ Contracts ============

const Controller = artifacts.require('Controller')
const TokenMaster = artifacts.require('TokenMaster')
const VaultCurve3Pool = artifacts.require('VaultCurve3Pool')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployVaultCurve3Pool(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployVaultCurve3Pool(deployer, network) {
  const controller = await Controller.deployed();
  const tokenMaster = await TokenMaster.deployed();

  await deployer.deploy(
    VaultCurve3Pool,
    controller.address,
    tokenMaster.address
  )
}
