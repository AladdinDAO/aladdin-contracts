// ============ Contracts ============

const ALDToken = artifacts.require('ALDToken')
const ISwapFactory = artifacts.require('ISwapFactory')

// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployLP(deployer, network),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployLP(deployer, network) {
  const aldToken = await ALDToken.deployed();
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
  const UNISWAP_FACTORT_ADDRESS = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
  const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  // create ETH-ALD pair in uniswap if not exist yet
  let swapFactory = await ISwapFactory.at(UNISWAP_FACTORT_ADDRESS);
  let WETH_ALD_LP_ADDRESS = await swapFactory.getPair(WETH_ADDRESS, aldToken.address);
  if (WETH_ALD_LP_ADDRESS == ZERO_ADDRESS) {
    console.log("creating WETH and ALD pair in uniswap");
    await swapFactory.createPair(WETH_ADDRESS, aldToken.address);
    WETH_ALD_LP_ADDRESS = await swapFactory.getPair(WETH_ADDRESS, aldToken.address);
    console.log("created WETH and ALD pair in uniswap, address: " + WETH_ALD_LP_ADDRESS);
  } else {
    console.log("WETH and ALD pair already exist in uniswap: " + WETH_ALD_LP_ADDRESS);
  }
}
