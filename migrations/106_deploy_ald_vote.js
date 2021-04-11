// ============ Contracts ============

const VoteToken = artifacts.require('VoteToken')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployVoteToken(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployVoteToken(deployer, network) {
  await deployer.deploy(VoteToken)
}
