// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCurve3Pool = artifacts.require('StrategyCurve3Pool')
const VaultCurve3Pool = artifacts.require('VaultCurve3Pool')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCurve3Pool(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCurve3Pool(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCurve3Pool,
    controller.address
  )

  const vault = await VaultCurve3Pool.deployed();
  const strategy = await StrategyCurve3Pool.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
