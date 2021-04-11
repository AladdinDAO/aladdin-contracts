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
    ["0x9d36e652Ab2C8Fa3738dCC73b3095197988E55B7"] // deployer
  )
}
