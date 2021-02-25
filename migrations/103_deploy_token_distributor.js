// ============ Contracts ============

const TokenDistributor = artifacts.require('TokenDistributor')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployTokenDistributor(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployTokenDistributor(deployer, network) {
  await deployer.deploy(
    TokenDistributor,
    ["0x82C718eA55b1FFE73200a985Bf55AaF56C1ABbDb"] // deployer
  )
}
