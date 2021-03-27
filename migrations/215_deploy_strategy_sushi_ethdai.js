// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategySushiETHDAI = artifacts.require('StrategySushiETHDAI')
const VaultSushiETHDAI = artifacts.require('VaultSushiETHDAI')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategySushiETHDAI(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategySushiETHDAI(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategySushiETHDAI,
    controller.address
  )

  const vault = await VaultSushiETHDAI.deployed();
  const strategy = await StrategySushiETHDAI.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
