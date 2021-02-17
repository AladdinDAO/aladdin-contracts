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
  await deployer.deploy(TokenMaster, defixToken.address, "0x82C718eA55b1FFE73200a985Bf55AaF56C1ABbDb") // deployer address

  // Add token master as minter to defix token
}
