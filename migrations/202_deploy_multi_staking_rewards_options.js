// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
const WrappedERC20 = artifacts.require('WrappedERC20')
const RewardDistributor = artifacts.require('RewardDistributor')
const MultiStakingRewards = artifacts.require('MultiStakingRewards')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployMultiStakingRewardsOptions(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployMultiStakingRewardsOptions(deployer, network) {
  const aldToken = await ALDToken.deployed();
  const wALDToken = await WrappedERC20.deployed();
  const rewardDistributor = await RewardDistributor.deployed();

  await deployer.deploy(
    MultiStakingRewards,
    aldToken.address,
    wALDToken.address,
    rewardDistributor.address
  )

  const multiStakingRewards = await MultiStakingRewards.deployed()
  await multiStakingRewards.addRewardPool(wALDToken.address, 378432000) // 12 month
}
