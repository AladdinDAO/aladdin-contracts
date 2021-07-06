// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
const TokenMaster = artifacts.require('TokenMaster')
const TokenDistributor = artifacts.require('TokenDistributor')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployTokenMaster(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployTokenMaster(deployer, network) {
  const aldToken = await ALDToken.deployed();
  const tokenDistributor = await TokenDistributor.deployed();
  const aldPerBlock = '1000000000000000000000' // 1000 ALD, temporary
  const startBlock = '99999999999999999' // temporary
  await deployer.deploy(TokenMaster, aldToken.address, tokenDistributor.address, aldPerBlock, startBlock)

  const tokenMaster = await TokenMaster.deployed();
  await aldToken.setMinter(tokenMaster.address, true)
}
