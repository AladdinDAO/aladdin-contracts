// ============ Contracts ============

const DefixToken = artifacts.require('DefixToken')
const DAO = artifacts.require('DAO')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployDAO(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployDAO(deployer, network) {
  const defix = await DefixToken.deployed()

  await deployer.deploy(
    DAO,
    "0x07de306FF27a2B630B1141956844eB1552B956B5", // USDT
    defix.address,
    "10",
    "2",
    ["0x82C718eA55b1FFE73200a985Bf55AaF56C1ABbDb"] // deployer
  )
}
