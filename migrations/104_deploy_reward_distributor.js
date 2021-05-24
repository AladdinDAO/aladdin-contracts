require('dotenv-flow').config();

// ============ Contracts ============

const RewardDistributor = artifacts.require('RewardDistributor')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployRewardDistributor(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployRewardDistributor(deployer, network) {
  await deployer.deploy(
    RewardDistributor,
    [process.env.DEPLOYER_ACCOUNT]
  )
}
