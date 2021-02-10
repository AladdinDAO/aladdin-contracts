// ============ Contracts ============

const DAOFunding = artifacts.require('DAOFunding')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployDAOFunding(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployDAOFunding(deployer, network) {
  await deployer.deploy(
    DAOFunding,
    "0xb7a4F3E9097C08dA09517b5aB877F7a917224ede", // USDC
    "0x21fe87a0d0695a5701547fe61caf325ada0F923e", // Defix Token
    "10",
    "2",
    ["0x82C718eA55b1FFE73200a985Bf55AaF56C1ABbDb"] // deployer
  )
}
