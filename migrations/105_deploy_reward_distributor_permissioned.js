// ============ Contracts ============

const RewardDistributorPermissioned = artifacts.require('RewardDistributorPermissioned')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployRewardDistributorPermissioned(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployRewardDistributorPermissioned(deployer, network) {
  await deployer.deploy(
    RewardDistributorPermissioned
  )
}
