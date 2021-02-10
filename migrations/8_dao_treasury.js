// ============ Contracts ============

const DAOTreasury = artifacts.require('DAOTreasury')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployDAOTreasury(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployDAOTreasury(deployer, network) {
  await deployer.deploy(DAOTreasury)
}
