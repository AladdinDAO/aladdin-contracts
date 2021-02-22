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
    ["0x82C718eA55b1FFE73200a985Bf55AaF56C1ABbDb"] // deployer
  )
}
