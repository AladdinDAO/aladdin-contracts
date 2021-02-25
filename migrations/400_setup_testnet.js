// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
const DAO = artifacts.require('DAO')
const WrappedERC20 = artifacts.require('WrappedERC20')
const MultiStakingRewards = artifacts.require('MultiStakingRewards')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    setupContracts(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function setupContracts(deployer, network) {
  const aldToken = await ALDToken.deployed();
  const dao = await DAO.deployed()
  const wALD = await WrappedERC20.deployed()
  const multiStakingRewards = await MultiStakingRewards.deployed()

  // add deployer as minter and mint
  await aldToken.setMinter("0x82C718eA55b1FFE73200a985Bf55AaF56C1ABbDb", true) // deployer
  const oneMillion = "1000000000000000000000000"
  await aldToken.mint("0x82C718eA55b1FFE73200a985Bf55AaF56C1ABbDb", oneMillion) // deployer
  console.log('minted ald')
  // add to dao whitelist
  await dao.addToWhitelist("0x561ADa4B0243F1d83dF80D1653E9F76E84128b0b") // gao
  console.log('added addresses to dao whitelist')
  // send rewards to multistakingrewards
  await multiStakingRewards.setRewardsDistribution("0x82C718eA55b1FFE73200a985Bf55AaF56C1ABbDb") // deployer
  await multiStakingRewards.addRewardPool(wALD.address, 604800) // 7 days
  console.log('added wALD reward pool to staking rewards')
  await aldToken.approve(wALD.address, oneMillion)
  await wALD.wrap(multiStakingRewards.address, oneMillion)
  console.log('wrapped ALD and sent to staking rewards')
  await multiStakingRewards.notifyRewardAmount(wALD.address, oneMillion)
  console.log('notified staking rewards')
}
