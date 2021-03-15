// ============ Contracts ============

const Controller = artifacts.require('Controller')
const TokenMaster = artifacts.require('TokenMaster')
const VaultCurveAave3Pool = artifacts.require('VaultCurveAave3Pool')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployVaultCurveAave3Pool(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployVaultCurveAave3Pool(deployer, network) {
  const controller = await Controller.deployed();
  const tokenMaster = await TokenMaster.deployed();

  await deployer.deploy(
    VaultCurveAave3Pool,
    controller.address,
    tokenMaster.address
  )
}
