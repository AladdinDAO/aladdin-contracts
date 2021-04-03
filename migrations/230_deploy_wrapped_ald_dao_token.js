// ============ Contracts ============

const DAO = artifacts.require('DAO')
const WrappedERC20 = artifacts.require('WrappedERC20')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployWrappedERC20(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployWrappedERC20(deployer, network) {
  const aldDAOToken = await DAO.deployed();
  await deployer.deploy(WrappedERC20, aldDAOToken.address, "Wrapped Aladdin DAO Token", "wALDDAO")
}
