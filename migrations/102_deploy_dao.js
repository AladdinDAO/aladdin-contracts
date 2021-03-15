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
    "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
    "10",
    "2",
    ["0x7B83E732Bf2b1Ed4442D6BfA546C387f1A4919bc"] // deployer
  )
}
