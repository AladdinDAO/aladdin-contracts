// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCurveRenWBTC = artifacts.require('StrategyCurveRenWBTC')
const VaultCurveRenWBTC = artifacts.require('VaultCurveRenWBTC')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCurveRenWBTC(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCurveRenWBTC(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCurveRenWBTC,
    controller.address
  )

  const vault = await VaultCurveRenWBTC.deployed();
  const strategy = await StrategyCurveRenWBTC.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
