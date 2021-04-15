// ============ Contracts ============

const Controller = artifacts.require('Controller')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployController(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployController(deployer, network) {
  await deployer.deploy(Controller)
}
