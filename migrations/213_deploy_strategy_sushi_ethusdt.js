// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategySushiETHUSDT = artifacts.require('StrategySushiETHUSDT')
const VaultSushiETHUSDT = artifacts.require('VaultSushiETHUSDT')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategySushiETHUSDT(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategySushiETHUSDT(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategySushiETHUSDT,
    controller.address
  )

  const vault = await VaultSushiETHUSDT.deployed();
  const strategy = await StrategySushiETHUSDT.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
