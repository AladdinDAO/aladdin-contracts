// ============ Contracts ============

const DAO = artifacts.require('DAO')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployDAO(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployDAO(deployer, network) {
  await deployer.deploy(
    DAO,
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
    "5000000000",
    "10",
    ["0x7B83E732Bf2b1Ed4442D6BfA546C387f1A4919bc"] // deployer
  )
}
