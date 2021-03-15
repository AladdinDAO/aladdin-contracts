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
    ["0x7B83E732Bf2b1Ed4442D6BfA546C387f1A4919bc"] // deployer
  )
}
