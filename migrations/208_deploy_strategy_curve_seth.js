// ============ Contracts ============

const Controller = artifacts.require('Controller')
const StrategyCurveSETH = artifacts.require('StrategyCurveSETH')
const VaultCurveSETH = artifacts.require('VaultCurveSETH')
const TokenMaster = artifacts.require('TokenMaster')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployStrategyCurveSETH(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployStrategyCurveSETH(deployer, network) {
  const controller = await Controller.deployed();

  await deployer.deploy(
    StrategyCurveSETH,
    controller.address
  )

  const vault = await VaultCurveSETH.deployed();
  const strategy = await StrategyCurveSETH.deployed()
  const tokenMaster = await TokenMaster.deployed();

  await controller.setStrategy(vault.address, strategy.address)
  await tokenMaster.add("100", vault.address, true)
}
