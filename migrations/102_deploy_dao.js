require('dotenv-flow').config();

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
    "3300000000",
    "10",
    [process.env.DEPLOYER_ACCOUNT]
  )
}
