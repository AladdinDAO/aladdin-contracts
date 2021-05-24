// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategySushiETHWBTC = artifacts.require('StrategySushiETHWBTC')
const VaultSushiETHWBTC = artifacts.require('VaultSushiETHWBTC')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategySushiETHWBTC(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategySushiETHWBTC(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategySushiETHWBTC,
    controller.address
  )

  const vault = await VaultSushiETHWBTC.deployed();
  const strategy = await StrategySushiETHWBTC.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
