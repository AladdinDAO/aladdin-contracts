// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
const ALDPlus = artifacts.require('ALDPlus')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployALDPlus(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployALDPlus(deployer, network) {
  const aldToken = await ALDToken.deployed();
  await deployer.deploy(ALDPlus, aldToken.address)
}
