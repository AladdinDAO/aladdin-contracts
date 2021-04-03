// ============ Contracts ============

const DAO = artifacts.require('DAO')
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
  const aldDAOToken = await DAO.deployed();
  const wALDDAOToken = await WrappedERC20.deployed();
  const rewardDistributor = await RewardDistributor.deployed();

  await deployer.deploy(
    MultiStakingRewards,
    aldDAOToken.address,
    wALDDAOToken.address,
    rewardDistributor.address
  )
}
