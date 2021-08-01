// ============ Contracts ============

const Keeper = artifacts.require('Keeper')
const VaultCurveSETH = artifacts.require('VaultCurveSETH')
const VaultCurveRenWBTC = artifacts.require('VaultCurveRenWBTC')
const VaultSushiETHWBTC = artifacts.require('VaultSushiETHWBTC')
const VaultCurve3Pool = artifacts.require('VaultCurve3Pool')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployKeeper(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployKeeper(deployer, network) {
  const vaultCurveSETH = await VaultCurveSETH.deployed()
  const vaultCurveRenWBTC = await VaultCurveRenWBTC.deployed()
  const vaultSushiETHWBTC = await VaultSushiETHWBTC.deployed()
  const vaultCurve3Pool = await VaultCurve3Pool.deployed()

  const vaults = [vaultCurveSETH.address, vaultCurveRenWBTC.address, vaultSushiETHWBTC.address, vaultCurve3Pool.address]
  await deployer.deploy(
    Keeper,
    vaults
  )
}
