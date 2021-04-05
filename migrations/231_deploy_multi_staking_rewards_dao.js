// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
const DAO = artifacts.require('DAO')
const WrappedERC20 = artifacts.require('WrappedERC20')
const RewardDistributor = artifacts.require('RewardDistributor')
const MultiStakingRewards = artifacts.require('MultiStakingRewards')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployMultiStakingRewardsDAO(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployMultiStakingRewardsDAO(deployer, network) {
  const aldToken = await ALDToken.deployed();
  const aldDAOToken = await DAO.deployed();
  const wALDDAOToken = await WrappedERC20.deployed();
  const rewardDistributor = await RewardDistributor.deployed();

  await deployer.deploy(
    MultiStakingRewards,
    aldDAOToken.address,
    wALDDAOToken.address,
    rewardDistributor.address
  )

  const multiStakingRewards = await MultiStakingRewards.deployed()
  await multiStakingRewards.addRewardPool(aldToken.address, 378432000) // 12 month
}
