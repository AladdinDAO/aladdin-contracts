// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCurveAave3pool = artifacts.require('StrategyCurveAave3pool')
const VaultCurveAave3pool = artifacts.require('VaultCurveAave3pool')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCurveAave3pool(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCurveAave3pool(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCurveAave3pool,
    controller.address
  )

  const vault = await VaultCurveAave3pool.deployed();
  const strategy = await StrategyCurveAave3pool.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
