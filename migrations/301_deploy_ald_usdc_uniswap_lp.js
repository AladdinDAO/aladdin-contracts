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
  const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  // create ETH-ALD pair in uniswap if not exist yet
  let swapFactory = await ISwapFactory.at(UNISWAP_FACTORT_ADDRESS);
  let USDC_ALD_LP_ADDRESS = await swapFactory.getPair(USDC_ADDRESS, aldToken.address);
  if (USDC_ALD_LP_ADDRESS == ZERO_ADDRESS) {
    console.log("creating USDC and ALD pair in uniswap");
    let result = await swapFactory.createPair(USDC_ADDRESS, aldToken.address);
    USDC_ALD_LP_ADDRESS = await swapFactory.getPair(USDC_ADDRESS, aldToken.address);
    console.log("created USDC and ALD pair in uniswap, address: " + USDC_ALD_LP_ADDRESS);
  } else {
    console.log("USDC and ALD pair already exist in uniswap: " + USDC_ALD_LP_ADDRESS);
  }
}
