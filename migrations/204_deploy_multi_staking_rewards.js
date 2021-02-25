// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
const WrappedERC20 = artifacts.require('WrappedERC20')
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
  const wALDToken = await WrappedERC20.deployed();
  const rewardDistributor = await RewardDistributor.deployed();

  await deployer.deploy(
    MultiStakingRewards,
    aldToken.address,
    wALDToken.address,
    rewardDistributor.address
  )
}
