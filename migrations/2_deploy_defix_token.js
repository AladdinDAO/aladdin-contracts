// ============ Contracts ============

const DefixToken = artifacts.require('DefixToken')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployDefixToken(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployDefixToken(deployer, network) {
  await deployer.deploy(DefixToken)
}
