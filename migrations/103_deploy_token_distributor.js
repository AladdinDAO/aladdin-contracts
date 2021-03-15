// ============ Contracts ============

const TokenDistributor = artifacts.require('TokenDistributor')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployTokenDistributor(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployTokenDistributor(deployer, network) {
  await deployer.deploy(
    TokenDistributor,
    ["0x7B83E732Bf2b1Ed4442D6BfA546C387f1A4919bc"] // deployer
  )
}
