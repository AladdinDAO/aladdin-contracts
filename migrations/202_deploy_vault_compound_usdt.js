// ============ Contracts ============

const Controller = artifacts.require('Controller')
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
  const controller = await Controller.deployed();
  const tokenMaster = await TokenMaster.deployed();

  await deployer.deploy(
    Vault,
    "0xdAC17F958D2ee523a2206206994597C13D831ec7", // usdt
    "0xc00e94Cb662C3520282E6f5717214004A7f26888", // comp
    controller.address,
    tokenMaster.address
  )
}
