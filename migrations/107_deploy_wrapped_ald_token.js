// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
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
  const aldToken = await ALDToken.deployed();
  await deployer.deploy(WrappedERC20, aldToken.address, "Wrapped Aladdin Token", "wALD")
}
