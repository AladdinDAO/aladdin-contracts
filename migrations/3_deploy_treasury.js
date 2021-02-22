// ============ Contracts ============

const Treasury = artifacts.require('Treasury')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployTreasury(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployTreasury(deployer, network) {
  await deployer.deploy(Treasury)
}
