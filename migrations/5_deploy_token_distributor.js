// ============ Contracts ============

const DefixToken = artifacts.require('DefixToken')
const DAOFunding = artifacts.require('DAOFunding')
const DAOTreasury = artifacts.require('DAOTreasury')
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
  const defix = await DefixToken.deployed()
  const daoFunding = await DAOFunding.deployed()
  const daoTreasury = await DAOTreasury.deployed()

  await deployer.deploy(
    TokenDistributor,
    defix.address,
    daoFunding.address,
    daoTreasury.address
  )
}
