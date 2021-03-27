// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCurveHBTC = artifacts.require('StrategyCurveHBTC')
const VaultCurveHBTC = artifacts.require('VaultCurveHBTC')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCurveHBTC(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCurveHBTC(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCurveHBTC,
    controller.address
  )

  const vault = await VaultCurveHBTC.deployed();
  const strategy = await StrategyCurveHBTC.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
