// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
const RewardDistributor = artifacts.require('RewardDistributor')
const MultiStakingRewards = artifacts.require('MultiStakingRewards')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployMultiStakingRewards(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployMultiStakingRewards(deployer, network) {
  const aldToken = await ALDToken.deployed();
  const rewardDistributor = await RewardDistributor.deployed();

  await deployer.deploy(
    MultiStakingRewards,
    aldToken.address,
    rewardDistributor.address
  )
}
