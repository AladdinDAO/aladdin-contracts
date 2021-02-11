// ============ Contracts ============

const DefixToken = artifacts.require('DefixToken')
const TokenMaster = artifacts.require('TokenMaster')

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
  await deployer.deploy(TokenMaster, defixToken.address)

  // Add token master as minter to defix token
}
