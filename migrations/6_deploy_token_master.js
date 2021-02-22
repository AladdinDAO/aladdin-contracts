// ============ Contracts ============

const DefixToken = artifacts.require('DefixToken')
const TokenMaster = artifacts.require('TokenMaster')
const TokenDistributor = artifacts.require('TokenDistributor')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployTokenMaster(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployTokenMaster(deployer, network) {
  const defixToken = await DefixToken.deployed();
  const tokenDistributor = await TokenDistributor.deployed();
  await deployer.deploy(TokenMaster, defixToken.address, tokenDistributor.address)

  const tokenMaster = await TokenMaster.deployed();
  await defixToken.setMinter(tokenMaster.address, true)
}
