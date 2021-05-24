// ============ Contracts ============

const Controller = artifacts.require('Controller')
const TokenMaster = artifacts.require('TokenMaster')
const VaultCurveSETH = artifacts.require('VaultCurveSETH')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployVaultCurveSETH(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployVaultCurveSETH(deployer, network) {
  const controller = await Controller.deployed();
  const tokenMaster = await TokenMaster.deployed();

  await deployer.deploy(
    VaultCurveSETH,
    controller.address,
    tokenMaster.address
  )
}
