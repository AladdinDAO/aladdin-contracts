/* eslint-disable no-process-exit */
/* eslint-disable camelcase */
/* eslint-disable node/no-missing-import */
import { constants, BigNumber } from "ethers";
import { ethers, upgrades } from "hardhat";
import {
  Airdrop,
  Airdrop__factory,
  ChainlinkPriceOracle,
  ChainlinkPriceOracle__factory,
  DAODistributor,
  DAODistributor__factory,
  DirectBondDepositor,
  DirectBondDepositor__factory,
  Distributor,
  Distributor__factory,
  ERC20,
  ERC20__factory,
  Keeper,
  Keeper__factory,
  RewardBondDepositor,
  RewardBondDepositor__factory,
  Staking,
  Staking__factory,
  Treasury,
  Treasury__factory,
  UniswapV2PairPriceOracle,
  UniswapV2PairPriceOracle__factory,
  UniswapV2PriceOracle,
  UniswapV2PriceOracle__factory,
  WrappedXALD,
  WrappedXALD__factory,
  XALD,
  XALD__factory,
} from "../typechain";

const CHAINLINK_FEEDS: { [name: string]: string } = {
  SPELL: "0x8c110B94C5f1d347fAcF5E1E938AB2db60E3c9a8", // Chainlink: SPELL/USD Price Feed
  WETH: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419", // Chainlink: ETH/USD Price Feed
  WBTC: "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c", // Chainlink: BTC/USD Price Feed
  CRV: "0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f", // Chainlink: CRV/USD Price Feed
  DAI: "0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9", // Chainlink: DAI/USD Price Feed
  USDC: "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6", // Chainlink: USDC/USD Price Feed
};

const UNISWAP_ETH_PAIRS: { [name: string]: string } = {
  CVX: "0x05767d9EF41dC40689678fFca0608878fb3dE906", // Sushi CVX/ETH Pair
  LDO: "0xC558F600B34A5f69dD2f0D06Cb8A88d829B7420a", // Sushi LDO/ETH Pair
};

const discount: { [name: string]: BigNumber } = {
  DAI: ethers.utils.parseEther("1"), // 100%
  USDC: ethers.utils.parseEther("1"), // 100%
  WBTC: ethers.utils.parseEther("1"), // 100%
  WETH: ethers.utils.parseEther("1"), // 100%
  SPELL: ethers.utils.parseEther("1"), // 100%
  CRV: ethers.utils.parseEther("1"), // 100%
  CVX: ethers.utils.parseEther("1"), // 100%
  LDO: ethers.utils.parseEther("1"), // 100%
  ALDWETH: ethers.utils.parseEther("1"), // 100%
  ALDUSDC: ethers.utils.parseEther("1"), // 100%
};

const PERCENTAGE_POL: { [name: string]: BigNumber } = {
  DAI: ethers.utils.parseEther("0.5"), // 50%
  USDC: ethers.utils.parseEther("0.5"), // 50%
  WBTC: ethers.utils.parseEther("0.5"), // 50%
  WETH: ethers.utils.parseEther("0.5"), // 50%
  SPELL: ethers.utils.parseEther("0.5"), // 50%
  CRV: ethers.utils.parseEther("0.5"), // 50%
  CVX: ethers.utils.parseEther("0.5"), // 50%
  LDO: ethers.utils.parseEther("0.5"), // 50%
};

const TOTAL_RESERVE = {
  underlying: constants.Zero,
  reward: constants.Zero,
  lp: ethers.utils.parseEther("1500000"),
};

const PERCENTAGE_CONTRIBUTOR = ethers.utils.parseEther("0.5"); // 50%

const MANAGER_MULTISIGN = constants.AddressZero;

const COMMUNITY_MULTISIGN = constants.AddressZero;

const POL_SPENDER = constants.AddressZero;

const FIRST_EPOCH_START_BLOCK = 0;

const EPOCH_LENGTH = 6400;

const ENABLE_STAKING_WHITELIST = true;

const STAKING_PAUSED = true;

const REWARD_RATE = constants.Zero;

const config: {
  tokens: {
    [name: string]: string;
  };
  ald: string;
  dao?: string;
  xald?: string;
  wxald?: string;
  treasury?: string;
  oracles: {
    chainlink?: string;
    uniswapETH?: string;
    uniswapPair?: string;
  };
  rewardBond?: string;
  directBond?: string;
  staking?: string;
  distributor?: string;
  keeper?: string;
  airdrop?: string;
} = {
  tokens: {
    DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    WBTC: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
    USDC: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    CRV: "0xD533a949740bb3306d119CC777fa900bA034cd52",
    CVX: "0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B",
    LDO: "0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32",
    SPELL: "0x090185f2135308BaD17527004364eBcC2D37e5F6",
    ALDWETH: "0xED6c2F053AF48Cba6cBC0958124671376f01A903",
    ALDUSDC: "0xaAa2bB0212Ec7190dC7142cD730173b0A788eC31",
  },
  ald: "0xb26C4B3Ca601136Daf98593feAeff9E0CA702a8D",
  dao: undefined,
  xald: undefined,
  wxald: undefined,
  treasury: undefined,
  oracles: {
    chainlink: undefined,
    uniswapETH: undefined,
    uniswapPair: undefined,
  },
  rewardBond: undefined,
  directBond: undefined,
  staking: undefined,
  distributor: undefined,
  keeper: undefined,
  airdrop: undefined,
};

let dao: DAODistributor;
let ald: ERC20;
let xald: XALD;
let wxald: WrappedXALD;
let treasury: Treasury;
let chainlink: ChainlinkPriceOracle;
let uniswapETH: UniswapV2PriceOracle;
let uniswapPair: UniswapV2PairPriceOracle;
let rewardBond: RewardBondDepositor;
let directBond: DirectBondDepositor;
let keeper: Keeper;
let airdrop: Airdrop;
let staking: Staking;
let distributor: Distributor;

async function setupReserveToken() {
  // setup reserve tokens
  for (const name of ["USDC", "DAI", "WBTC", "WETH", "CRV", "SPELL", "LDO", "CVX"]) {
    const address = config.tokens[name];
    if (!(await treasury.isReserveToken(address))) {
      console.log("add", name, "to reserve");
      const tx = await treasury.updateReserveToken(address, true);
      await tx.wait();
    }
    if (!(await treasury.discount(address)).eq(discount[name])) {
      console.log("update discount for", name, "to:", ethers.utils.formatEther(discount[name]));
      const tx = await treasury.updateDiscount(address, discount[name]);
      await tx.wait();
    }
    if (!(await treasury.percentagePOL(address)).eq(PERCENTAGE_POL[name])) {
      console.log("update percentagePOL for", name, "to:", ethers.utils.formatEther(PERCENTAGE_POL[name]));
      const tx = await treasury.updatePercentagePOL(address, PERCENTAGE_POL[name]);
      await tx.wait();
    }
  }
  // setup liquidity tokens
  for (const name of ["ALDWETH", "ALDUSDC"]) {
    const address = config.tokens[name];
    if (!(await treasury.isLiquidityToken(address))) {
      console.log("add", name, "to liquidity token");
      const tx = await treasury.updateLiquidityToken(address, true);
      await tx.wait();
    }
    if (!(await treasury.discount(address)).eq(discount[name])) {
      console.log("update discount for", name, "to:", ethers.utils.formatEther(discount[name]));
      const tx = await treasury.updateDiscount(address, discount[name]);
      await tx.wait();
    }
    if (!(await treasury.percentagePOL(address)).eq(PERCENTAGE_POL[name])) {
      console.log("update percentagePOL for", name, "to:", ethers.utils.formatEther(PERCENTAGE_POL[name]));
      const tx = await treasury.updatePercentagePOL(address, PERCENTAGE_POL[name]);
      await tx.wait();
    }
  }
}

async function setupOracle() {
  // setup chainlink oracle
  for (const name of ["DAI", "USDC", "WBTC", "WETH", "CRV", "SPELL"]) {
    const address = config.tokens[name];
    const feed = CHAINLINK_FEEDS[name];
    if ((await chainlink.feeds(address)) !== feed) {
      console.log("Set chainlink feed for", name);
      const tx = await chainlink.updateFeed(address, feed);
      await tx.wait();
    }
    console.log("price ", name, ethers.utils.formatEther(await chainlink.price(address)));
    if ((await treasury.priceOracle(address)) !== chainlink.address) {
      console.log("Set Treasury price oracle feed for", name);
      const tx = await treasury.updatePriceOracle(address, chainlink.address);
      await tx.wait();
    }
  }

  // setup uniswap v2 oracle
  for (const name of ["LDO", "CVX"]) {
    const address = config.tokens[name];
    const pair = UNISWAP_ETH_PAIRS[name];
    if ((await uniswapETH.pairs(address)) !== pair) {
      console.log("Set uniswap pair for", name);
      const tx = await uniswapETH.updatePair(address, pair);
      await tx.wait();
    }
    console.log("price ", name, ethers.utils.formatEther(await uniswapETH.price(address)));
    if ((await treasury.priceOracle(address)) !== uniswapETH.address) {
      console.log("Set Treasury price oracle feed for", name);
      const tx = await treasury.updatePriceOracle(address, uniswapETH.address);
      await tx.wait();
    }
  }

  // setup uniswap v2 oracle
  for (const name of ["ALDWETH", "ALDUSDC"]) {
    const address = config.tokens[name];
    if ((await treasury.priceOracle(address)) !== uniswapPair.address) {
      console.log("Set Treasury price oracle feed for", name);
      const tx = await treasury.updatePriceOracle(address, uniswapPair.address);
      await tx.wait();
    }
    console.log("price ", name, ethers.utils.formatEther(await uniswapPair.price(address)));
  }
}

async function setupBond() {
  // initialize staking contract for reward bond
  if ((await rewardBond.staking()) === constants.AddressZero) {
    console.log("Initialize RewardBondDepositor");
    const tx = await rewardBond.initializeStaking(staking.address);
    await tx.wait();
  }

  // setup keeper for reward bond
  if ((await rewardBond.keeper()) !== keeper.address) {
    console.log("Initialize Keeper for RewardBondDepositor");
    const tx = await rewardBond.updateKeeper(keeper.address);
    await tx.wait();
  }

  // initialize staking contract for direct bond
  if ((await directBond.staking()) === constants.AddressZero) {
    console.log("Initialize DirectBondDepositor");
    const tx = await directBond.initialize(staking.address);
    await tx.wait();
  }

  // setup asset for direct bond
  for (const name of ["USDC", "WBTC", "WETH", "DAI", "ALDWETH", "ALDUSDC"]) {
    const address = config.tokens[name];
    if (!(await directBond.isBondAsset(address))) {
      console.log("add", name, "to bond");
      const tx = await directBond.updateBondAsset(address, true);
      await tx.wait();
    }
  }
}

async function setupStaking() {
  // setup distributor
  if ((await staking.distributor()) !== distributor.address) {
    console.log("setup distributor in staking");
    const tx = await staking.updateDistributor(distributor.address);
    await tx.wait();
  }

  // pause/unpause staking
  if ((await staking.paused()) !== STAKING_PAUSED) {
    if (STAKING_PAUSED) {
      console.log("pause staking");
    } else {
      console.log("unpause staking");
    }
    const tx = await staking.updatePaused(STAKING_PAUSED);
    await tx.wait();
  }

  // enable/disable whitelist in staking
  if ((await staking.enableWhitelist()) !== ENABLE_STAKING_WHITELIST) {
    if (ENABLE_STAKING_WHITELIST) {
      console.log("enable whitelist in staking");
    } else {
      console.log("disable whitelist in staking");
    }
    const tx = await staking.updateEnableWhitelist(ENABLE_STAKING_WHITELIST);
    await tx.wait();
  }
}

async function setupTreasury() {
  // update reward manager
  if (!(await treasury.isRewardManager(distributor.address))) {
    console.log("set distributor as RewardManager in treasury");
    const tx = await treasury.updateRewardManager(distributor.address, true);
    await tx.wait();
  }

  // update reserve depositor
  if (!(await treasury.isReserveDepositor(directBond.address))) {
    console.log("set direct bond as ReserveDepositor in treasury");
    const tx = await treasury.updateReserveDepositor(directBond.address, true);
    await tx.wait();
  }

  if (!(await treasury.isReserveDepositor(rewardBond.address))) {
    console.log("set reward bond as ReserveDepositor in treasury");
    const tx = await treasury.updateReserveDepositor(rewardBond.address, true);
    await tx.wait();
  }

  // setup reserve
  if ((await treasury.totalReserveLiquidityToken()).eq(constants.Zero)) {
    console.log("set reserve for treasury");
    const tx = await treasury.updateReserves(TOTAL_RESERVE.underlying, TOTAL_RESERVE.reward, TOTAL_RESERVE.lp);
    await tx.wait();
  }
}

async function main() {
  const [deployer] = await ethers.getSigners();

  // ALD
  ald = ERC20__factory.connect(config.ald, deployer);
  console.log("Found ALD at:", ald.address);

  // deploy DAODistributor
  if (config.dao === undefined) {
    const DAODistributor = await ethers.getContractFactory("DAODistributor", deployer);
    dao = await DAODistributor.deploy(ald.address, deployer.address);
    await dao.deployed();
    config.dao = dao.address;
    console.log("Deploy DAODistributor at:", dao.address);
  } else {
    dao = DAODistributor__factory.connect(config.dao, deployer);
    console.log("Found DAODistributor at:", dao.address);
  }

  // deploy XALD
  if (config.xald === undefined) {
    const XALD = await ethers.getContractFactory("XALD", deployer);
    xald = await XALD.deploy();
    await xald.deployed();
    config.xald = xald.address;
    console.log("Deploy XALD at:", xald.address);
  } else {
    xald = XALD__factory.connect(config.xald, deployer);
    console.log("Found XALD at:", xald.address);
  }

  // deploy WrappedXALD
  if (config.wxald === undefined) {
    const WrappedXALD = await ethers.getContractFactory("WrappedXALD", deployer);
    wxald = await WrappedXALD.deploy(xald.address);
    await wxald.deployed();
    config.wxald = wxald.address;
    console.log("Deploy WrappedXALD at:", wxald.address);
  } else {
    wxald = WrappedXALD__factory.connect(config.wxald, deployer);
    console.log("Found WrappedXALD at:", wxald.address);
  }

  // deploy Treasury
  if (config.treasury === undefined) {
    const Treasury = await ethers.getContractFactory("Treasury", deployer);
    treasury = await Treasury.deploy(ald.address, dao.address);
    await treasury.deployed();
    config.treasury = treasury.address;
    console.log("Deploy Treasury at:", treasury.address);
  } else {
    treasury = Treasury__factory.connect(config.treasury, deployer);
    console.log("Found Treasury at:", treasury.address);
  }

  // deploy ChainlinkPriceOracle
  if (config.oracles.chainlink === undefined) {
    const ChainlinkPriceOracle = await ethers.getContractFactory("ChainlinkPriceOracle", deployer);
    chainlink = await ChainlinkPriceOracle.deploy();
    await chainlink.deployed();
    config.oracles.chainlink = chainlink.address;
    console.log("Deploy ChainlinkPriceOracle at:", chainlink.address);
  } else {
    chainlink = ChainlinkPriceOracle__factory.connect(config.oracles.chainlink, deployer);
    console.log("Found ChainlinkPriceOracle at:", chainlink.address);
  }

  // deploy UniswapV2PriceOracle ETH base
  if (config.oracles.uniswapETH === undefined) {
    const UniswapV2PriceOracle = await ethers.getContractFactory("UniswapV2PriceOracle", deployer);
    uniswapETH = await UniswapV2PriceOracle.deploy(chainlink.address, config.tokens.WETH);
    await uniswapETH.deployed();
    config.oracles.uniswapETH = uniswapETH.address;
    console.log("Deploy UniswapV2PriceOracle at:", uniswapETH.address);
  } else {
    uniswapETH = UniswapV2PriceOracle__factory.connect(config.oracles.uniswapETH, deployer);
    console.log("Found UniswapV2PriceOracle at:", uniswapETH.address);
  }

  // deploy UniswapV2PairPriceOracle
  if (config.oracles.uniswapPair === undefined) {
    const UniswapV2PairPriceOracle = await ethers.getContractFactory("UniswapV2PairPriceOracle", deployer);
    uniswapPair = await UniswapV2PairPriceOracle.deploy(chainlink.address, ald.address);
    await uniswapETH.deployed();
    config.oracles.uniswapPair = uniswapPair.address;
    console.log("Deploy UniswapV2PairPriceOracle at:", uniswapPair.address);
  } else {
    uniswapPair = UniswapV2PairPriceOracle__factory.connect(config.oracles.uniswapPair, deployer);
    console.log("Found UniswapV2PairPriceOracle at:", uniswapPair.address);
  }

  // deploy RewardBondDepositor
  if (config.rewardBond === undefined) {
    const RewardBondDepositor = await ethers.getContractFactory("RewardBondDepositor", deployer);
    rewardBond = (await upgrades.deployProxy(RewardBondDepositor, [
      ald.address,
      treasury.address,
      FIRST_EPOCH_START_BLOCK,
      EPOCH_LENGTH,
    ])) as RewardBondDepositor;
    await rewardBond.deployed();
    config.rewardBond = rewardBond.address;
    console.log("Deploy RewardBondDepositor at:", rewardBond.address);
  } else {
    rewardBond = RewardBondDepositor__factory.connect(config.rewardBond, deployer);
    console.log("Found RewardBondDepositor at:", rewardBond.address);
  }

  // deploy DirectBondDepositor
  if (config.directBond === undefined) {
    const DirectBondDepositor = await ethers.getContractFactory("DirectBondDepositor", deployer);
    directBond = await DirectBondDepositor.deploy(ald.address, treasury.address);
    await directBond.deployed();
    config.directBond = directBond.address;
    console.log("Deploy DirectBondDepositor at:", directBond.address);
  } else {
    directBond = DirectBondDepositor__factory.connect(config.directBond, deployer);
    console.log("Found DirectBondDepositor at:", directBond.address);
  }

  // deploy Staking
  if (config.staking === undefined) {
    const Staking = await ethers.getContractFactory("Staking", deployer);
    staking = (await upgrades.deployProxy(Staking, [
      ald.address,
      xald.address,
      wxald.address,
      directBond.address,
      rewardBond.address,
    ])) as Staking;
    await staking.deployed();
    config.staking = staking.address;
    console.log("Deploy Staking at:", staking.address);
  } else {
    staking = Staking__factory.connect(config.staking, deployer);
    console.log("Found Staking at:", staking.address);
  }

  // deploy Distributor
  if (config.distributor === undefined) {
    const Distributor = await ethers.getContractFactory("Distributor", deployer);
    distributor = await Distributor.deploy(ald.address, treasury.address, staking.address);
    await distributor.deployed();
    config.distributor = distributor.address;
    console.log("Deploy Distributor at:", distributor.address);
  } else {
    distributor = Distributor__factory.connect(config.distributor, deployer);
    console.log("Found Distributor at:", distributor.address);
  }

  // deploy Keeper
  if (config.keeper === undefined) {
    const Keeper = await ethers.getContractFactory("Keeper", deployer);
    keeper = await Keeper.deploy(rewardBond.address);
    await keeper.deployed();
    config.keeper = keeper.address;
    console.log("Deploy Keeper at:", keeper.address);
  } else {
    keeper = Keeper__factory.connect(config.keeper, deployer);
    console.log("Found Keeper at:", keeper.address);
  }

  // deploy Airdrop
  if (config.airdrop === undefined) {
    const Airdrop = await ethers.getContractFactory("Airdrop", deployer);
    airdrop = await Airdrop.deploy(ald.address, xald.address, wxald.address, staking.address);
    await airdrop.deployed();
    config.airdrop = airdrop.address;
    console.log("Deploy Airdrop at:", airdrop.address);
  } else {
    airdrop = Airdrop__factory.connect(config.airdrop, deployer);
    console.log("Found Airdrop at:", airdrop.address);
  }

  // setup xald
  if ((await xald.staking()) === constants.AddressZero) {
    console.log("Initialize XALD");
    const tx = await xald.initialize(staking.address);
    await tx.wait();
  }

  // setup reserve token
  await setupReserveToken();

  // setup oracle
  await setupOracle();

  // setup bond
  await setupBond();

  // setup treasudy
  await setupTreasury();

  // setup staking
  await setupStaking();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
