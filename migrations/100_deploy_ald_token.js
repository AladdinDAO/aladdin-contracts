// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployALDToken(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployALDToken(deployer, network) {
  await deployer.deploy(ALDToken)
}
