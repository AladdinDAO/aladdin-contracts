// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategySushiETHUSDC = artifacts.require('StrategySushiETHUSDC')
const VaultSushiETHUSDC = artifacts.require('VaultSushiETHUSDC')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategySushiETHUSDC(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategySushiETHUSDC(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategySushiETHUSDC,
    controller.address
  )

  const vault = await VaultSushiETHUSDC.deployed();
  const strategy = await StrategySushiETHUSDC.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
