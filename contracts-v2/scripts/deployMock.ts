/* eslint-disable camelcase */
/* eslint-disable node/no-missing-import */
import { constants, BigNumber } from "ethers";
import { ethers } from "hardhat";
import {
  ChainlinkPriceOracle,
  ChainlinkPriceOracle__factory,
  DirectBondDepositor,
  DirectBondDepositor__factory,
  Distributor,
  Distributor__factory,
  IUniswapV2Pair__factory,
  Keeper,
  Keeper__factory,
  MIMConvexVault,
  MIMConvexVault__factory,
  MockERC20,
  MockERC20__factory,
  RenConvexVault,
  RenConvexVault__factory,
  RewardBondDepositor,
  RewardBondDepositor__factory,
  Staking,
  Staking__factory,
  STETHConvexVault,
  STETHConvexVault__factory,
  Treasury,
  Treasury__factory,
  TriCrypto2ConvexVault,
  TriCrypto2ConvexVault__factory,
  TriPoolConvexVault,
  TriPoolConvexVault__factory,
  UniswapV2PairPriceOracle,
  UniswapV2PairPriceOracle__factory,
  UniswapV2PriceOracle,
  UniswapV2PriceOracle__factory,
  WrappedXALD,
  WrappedXALD__factory,
  XALD,
  XALD__factory,
} from "../typechain";

const chainlinkFeeds: { [name: string]: string } = {
  SPELL: "0x8c110B94C5f1d347fAcF5E1E938AB2db60E3c9a8",
  WETH: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
  WBTC: "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c",
  CRV: "0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f",
  DAI: "0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9",
  USDC: "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6",
};

const uniswapETHPairs: { [name: string]: string } = {
  CVX: "0x05767d9EF41dC40689678fFca0608878fb3dE906",
  LDO: "0xC558F600B34A5f69dD2f0D06Cb8A88d829B7420a",
};

const discount: { [name: string]: BigNumber } = {
  DAI: ethers.utils.parseEther("1"),
  WBTC: ethers.utils.parseEther("1"),
  WETH: ethers.utils.parseEther("1.1"),
  SPELL: ethers.utils.parseEther("1"),
  CRV: ethers.utils.parseEther("1"),
  CVX: ethers.utils.parseEther("1"),
  LDO: ethers.utils.parseEther("1"),
  ALDWETH: ethers.utils.parseEther("1.1"),
  ALDUSDC: ethers.utils.parseEther("1.1"),
};

const config: {
  tokens: {
    [name: string]: string;
  };
  dao: string;
  ald?: string;
  xald?: string;
  wxald?: string;
  treasury?: string;
  oracles: {
    chainlink?: string;
    uniswapETH?: string;
    uniswapUSDC?: string;
    uniswapPair?: string;
  };
  rewardBond?: string;
  directBond?: string;
  staking?: string;
  distributor?: string;
  keeper?: string;
  vaults: {
    convex: {
      mim?: string;
      ren?: string;
      steth?: string;
      tricrypto?: string;
      tripool?: string;
    };
  };
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
  dao: "0xB5495A8D85EE18cfD0d2816993658D88aF08bEF4",
  ald: "0xb26C4B3Ca601136Daf98593feAeff9E0CA702a8D",
  xald: "0x136A4eE47367C1937Aa34373E2C8ad92ECa2EB0f",
  wxald: "0x38CB2BFc78B125bDB4E76a80E05A4Ef9DF5B971e",
  treasury: "0xD96D57f291096AA637E7502b6D4282815d04f1AC",
  oracles: {
    chainlink: "0xbd39d1e57D649abB3B1208e262CAF9270728fd0d",
    uniswapETH: "0xb7396C5e1fF85c621A82CCAC0E5AC8De801f4220",
    uniswapPair: "0xB5F48bB848FEED0D152763F3495dE3f7eb90a4A2",
  },
  rewardBond: "0x829b2acC50D414E0B299f739220E90710F6A4735",
  directBond: "0x5350107530447E668a00F34E35EA5d355D8093C1",
  staking: "0x349567Bf61Ea412e400E0e2e8985406B621752C4",
  distributor: "0xb9D676Fe9B231419187a0BDF6A84199Bb0fEb39E",
  keeper: "0x8A7485dc9A2c59B3460318F505E23a1A6C4FA25e",
  vaults: {
    convex: {
      mim: "0xdcac69FCFDa36Ab7440EB55036b57EA7C607dbed",
      ren: "0x9d894F1DF8Da14271229B6C7F33F4e564a8B5028",
      steth: "0x24dBFD1F70a2E6a39516CC7D3330C0432Ff28534",
      tricrypto: "0xb287ba0d791229FFCeCdd009Bb70758460BF3985",
      tripool: "0x6A11D7eB1c885ad39e1E8E0b1250bcBb5c7689A1",
    },
  },
};

let ald: MockERC20;
let xald: XALD;
let wxald: WrappedXALD;
let treasury: Treasury;
let chainlink: ChainlinkPriceOracle;
let uniswapETH: UniswapV2PriceOracle;
let uniswapPair: UniswapV2PairPriceOracle;
let rewardBond: RewardBondDepositor;
let directBond: DirectBondDepositor;
let keeper: Keeper;
let staking: Staking;
let distributor: Distributor;

let mimVault: MIMConvexVault;
let renVault: RenConvexVault;
let stethVault: STETHConvexVault;
let tricryptoVault: TriCrypto2ConvexVault;
let tripoolVault: TriPoolConvexVault;

async function setupReserveToken() {
  // setup reserve tokens
  for (const name of ["DAI", "WBTC", "WETH", "CRV", "SPELL", "LDO", "CVX"]) {
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
  }
}

async function setupOracle() {
  // setup chainlink oracle
  for (const name of ["DAI", "USDC", "WBTC", "WETH", "CRV", "SPELL"]) {
    const address = config.tokens[name];
    const feed = chainlinkFeeds[name];
    if ((await chainlink.feeds(address)) !== feed) {
      console.log("Set chainlink feed for", name);
      const tx = await chainlink.updateFeed(address, feed);
      await tx.wait();
    }
    if ((await treasury.priceOracle(address)) !== chainlink.address) {
      console.log("Set Treasury price oracle feed for", name);
      const tx = await treasury.updatePriceOracle(address, chainlink.address);
      await tx.wait();
    }
  }

  // setup uniswap v2 oracle
  for (const name of ["LDO", "CVX"]) {
    const address = config.tokens[name];
    const pair = uniswapETHPairs[name];
    if ((await uniswapETH.pairs(address)) !== pair) {
      console.log("Set uniswap pair for", name);
      const tx = await uniswapETH.updatePair(address, pair);
      await tx.wait();
    }
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
  }
}

async function deployConvexVault() {
  const [deployer] = await ethers.getSigners();
  // depoly MIMConvexVault
  if (config.vaults.convex.mim === undefined) {
    const MIMConvexVault = await ethers.getContractFactory("MIMConvexVault", deployer);
    mimVault = await MIMConvexVault.deploy(rewardBond.address, await deployer.getAddress());
    await mimVault.deployed();
    config.vaults.convex.mim = mimVault.address;
    console.log("Deploy MIMConvexVault at:", config.vaults.convex.mim);
  } else {
    mimVault = MIMConvexVault__factory.connect(config.vaults.convex.mim, deployer);
    console.log("Found MIMConvexVault at:", config.vaults.convex.mim);
  }
  // depoly RenConvexVault
  if (config.vaults.convex.ren === undefined) {
    const RenConvexVault = await ethers.getContractFactory("RenConvexVault", deployer);
    renVault = await RenConvexVault.deploy(rewardBond.address, await deployer.getAddress());
    await renVault.deployed();
    config.vaults.convex.ren = renVault.address;
    console.log("Deploy RenConvexVault at:", config.vaults.convex.ren);
  } else {
    renVault = RenConvexVault__factory.connect(config.vaults.convex.ren, deployer);
    console.log("Found RenConvexVault at:", config.vaults.convex.ren);
  }
  // depoly STETHConvexVault
  if (config.vaults.convex.steth === undefined) {
    const STETHConvexVault = await ethers.getContractFactory("STETHConvexVault", deployer);
    stethVault = await STETHConvexVault.deploy(rewardBond.address, await deployer.getAddress());
    await stethVault.deployed();
    config.vaults.convex.steth = stethVault.address;
    console.log("Deploy STETHConvexVault at:", config.vaults.convex.steth);
  } else {
    stethVault = STETHConvexVault__factory.connect(config.vaults.convex.steth, deployer);
    console.log("Found STETHConvexVault at:", config.vaults.convex.steth);
  }
  // depoly TriCrypto2ConvexVault
  if (config.vaults.convex.tricrypto === undefined) {
    const TriCrypto2ConvexVault = await ethers.getContractFactory("TriCrypto2ConvexVault", deployer);
    tricryptoVault = await TriCrypto2ConvexVault.deploy(rewardBond.address, await deployer.getAddress());
    await tricryptoVault.deployed();
    config.vaults.convex.tricrypto = tricryptoVault.address;
    console.log("Deploy TriCrypto2ConvexVault at:", config.vaults.convex.tricrypto);
  } else {
    tricryptoVault = TriCrypto2ConvexVault__factory.connect(config.vaults.convex.tricrypto, deployer);
    console.log("Found TriCrypto2ConvexVault at:", config.vaults.convex.tricrypto);
  }
  // depoly TriPoolConvexVault
  if (config.vaults.convex.tripool === undefined) {
    const TriPoolConvexVault = await ethers.getContractFactory("TriPoolConvexVault", deployer);
    tripoolVault = await TriPoolConvexVault.deploy(rewardBond.address, await deployer.getAddress());
    await tripoolVault.deployed();
    config.vaults.convex.tripool = tripoolVault.address;
    console.log("Deploy TriPoolConvexVault at:", config.vaults.convex.tripool);
  } else {
    tripoolVault = TriPoolConvexVault__factory.connect(config.vaults.convex.tripool, deployer);
    console.log("Found TriPoolConvexVault at:", config.vaults.convex.tripool);
  }
  if (!(await keeper.isVault(mimVault.address))) {
    console.log("add mim vault to keeper");
    const tx = await keeper.updateVault(mimVault.address, true);
    await tx.wait();
  }
  if (!(await keeper.isVault(renVault.address))) {
    console.log("add ren vault to keeper");
    const tx = await keeper.updateVault(renVault.address, true);
    await tx.wait();
  }
  if (!(await keeper.isVault(stethVault.address))) {
    console.log("add steth vault to keeper");
    const tx = await keeper.updateVault(stethVault.address, true);
    await tx.wait();
  }
  if (!(await keeper.isVault(tricryptoVault.address))) {
    console.log("add tricrypto vault to keeper");
    const tx = await keeper.updateVault(tricryptoVault.address, true);
    await tx.wait();
  }
  if (!(await keeper.isVault(tripoolVault.address))) {
    console.log("add tripool vault to keeper");
    const tx = await keeper.updateVault(tripoolVault.address, true);
    await tx.wait();
  }
}

async function main() {
  const [deployer] = await ethers.getSigners();

  // Mock ALD
  if (config.ald === undefined) {
    const MockERC20 = await ethers.getContractFactory("MockERC20", deployer);
    ald = await MockERC20.deploy("Aladdin DAO Token", "ALD", 18);
    await ald.deployed();
    config.ald = ald.address;
    console.log("Deploy ALD at:", config.ald);
  } else {
    ald = MockERC20__factory.connect(config.ald, deployer);
    console.log("Found ALD at:", config.ald);
  }

  // XALD
  if (config.xald === undefined) {
    const XALD = await ethers.getContractFactory("XALD", deployer);
    xald = await XALD.deploy();
    await xald.deployed();
    config.xald = xald.address;
    console.log("Deploy XALD at:", config.xald);
  } else {
    xald = XALD__factory.connect(config.xald, deployer);
    console.log("Found XALD at:", config.xald);
  }

  // WrappedXALD
  if (config.wxald === undefined) {
    const WrappedXALD = await ethers.getContractFactory("WrappedXALD", deployer);
    wxald = await WrappedXALD.deploy(xald.address);
    await wxald.deployed();
    config.wxald = wxald.address;
    console.log("Deploy WrappedXALD at:", config.wxald);
  } else {
    wxald = WrappedXALD__factory.connect(config.wxald, deployer);
    console.log("Found WrappedXALD at:", config.wxald);
  }

  // Treasury
  if (config.treasury === undefined) {
    const Treasury = await ethers.getContractFactory("Treasury", deployer);
    treasury = await Treasury.deploy(ald.address, config.dao);
    await treasury.deployed();
    config.treasury = treasury.address;
    console.log("Deploy Treasury at:", config.treasury);
  } else {
    treasury = Treasury__factory.connect(config.treasury, deployer);
    console.log("Found Treasury at:", config.treasury);
  }

  await setupReserveToken();

  // ChainlinkPriceOracle
  if (config.oracles.chainlink === undefined) {
    const ChainlinkPriceOracle = await ethers.getContractFactory("ChainlinkPriceOracle", deployer);
    chainlink = await ChainlinkPriceOracle.deploy();
    await chainlink.deployed();
    config.oracles.chainlink = chainlink.address;
    console.log("Deploy ChainlinkPriceOracle at:", config.oracles.chainlink);
  } else {
    chainlink = ChainlinkPriceOracle__factory.connect(config.oracles.chainlink, deployer);
    console.log("Found ChainlinkPriceOracle at:", config.oracles.chainlink);
  }

  // UniswapV2PriceOracle ETH base
  if (config.oracles.uniswapETH === undefined) {
    const UniswapV2PriceOracle = await ethers.getContractFactory("UniswapV2PriceOracle", deployer);
    uniswapETH = await UniswapV2PriceOracle.deploy(chainlink.address, config.tokens.WETH);
    await uniswapETH.deployed();
    config.oracles.uniswapETH = uniswapETH.address;
    console.log("Deploy UniswapV2PriceOracle at:", config.oracles.uniswapETH);
  } else {
    uniswapETH = UniswapV2PriceOracle__factory.connect(config.oracles.uniswapETH, deployer);
    console.log("Found UniswapV2PriceOracle at:", config.oracles.uniswapETH);
  }

  // UniswapV2PairPriceOracle
  if (config.oracles.uniswapPair === undefined) {
    const UniswapV2PairPriceOracle = await ethers.getContractFactory("UniswapV2PairPriceOracle", deployer);
    uniswapPair = await UniswapV2PairPriceOracle.deploy(chainlink.address, config.ald);
    await uniswapETH.deployed();
    config.oracles.uniswapPair = uniswapPair.address;
    console.log("Deploy UniswapV2PairPriceOracle at:", config.oracles.uniswapPair);
  } else {
    uniswapPair = UniswapV2PairPriceOracle__factory.connect(config.oracles.uniswapPair, deployer);
    console.log("Found UniswapV2PairPriceOracle at:", config.oracles.uniswapPair);
  }

  await setupOracle();

  // RewardBondDepositor
  if (config.rewardBond === undefined) {
    const RewardBondDepositor = await ethers.getContractFactory("RewardBondDepositor", deployer);
    rewardBond = await RewardBondDepositor.deploy(ald.address, treasury.address, 6400);
    await rewardBond.deployed();
    config.rewardBond = rewardBond.address;
    console.log("Deploy RewardBondDepositor at:", config.rewardBond);
  } else {
    rewardBond = RewardBondDepositor__factory.connect(config.rewardBond, deployer);
    console.log("Found RewardBondDepositor at:", config.rewardBond);
  }

  // DirectBondDepositor
  if (config.directBond === undefined) {
    const DirectBondDepositor = await ethers.getContractFactory("DirectBondDepositor", deployer);
    directBond = await DirectBondDepositor.deploy(ald.address, treasury.address);
    await directBond.deployed();
    config.directBond = directBond.address;
    console.log("Deploy DirectBondDepositor at:", config.directBond);
  } else {
    directBond = DirectBondDepositor__factory.connect(config.directBond, deployer);
    console.log("Found DirectBondDepositor at:", config.directBond);
  }

  // Staking
  if (config.staking === undefined) {
    const Staking = await ethers.getContractFactory("Staking", deployer);
    staking = await Staking.deploy(ald.address, xald.address, wxald.address, directBond.address, rewardBond.address);
    await staking.deployed();
    config.staking = staking.address;
    console.log("Deploy Staking at:", config.staking);
  } else {
    staking = Staking__factory.connect(config.staking, deployer);
    console.log("Found Staking at:", config.staking);
  }

  // Distributor
  if (config.distributor === undefined) {
    const Distributor = await ethers.getContractFactory("Distributor", deployer);
    distributor = await Distributor.deploy(ald.address, treasury.address, staking.address);
    await distributor.deployed();
    config.distributor = distributor.address;
    console.log("Deploy Distributor at:", config.distributor);
  } else {
    distributor = Distributor__factory.connect(config.distributor, deployer);
    console.log("Found Distributor at:", config.distributor);
  }

  // Keeper
  if (config.keeper === undefined) {
    const Keeper = await ethers.getContractFactory("Keeper", deployer);
    keeper = await Keeper.deploy(rewardBond.address);
    await keeper.deployed();
    config.keeper = keeper.address;
    console.log("Deploy Keeper at:", config.keeper);
  } else {
    keeper = Keeper__factory.connect(config.keeper, deployer);
    console.log("Found Keeper at:", config.keeper);
  }

  // setup reward bond
  if ((await rewardBond.staking()) === constants.AddressZero) {
    console.log("Initialize RewardBondDepositor");
    const tx = await rewardBond.initialize(staking.address);
    await tx.wait();
  }

  // setup keeper
  if ((await rewardBond.keeper()) !== keeper.address) {
    console.log("Initialize Keeper for RewardBondDepositor");
    const tx = await rewardBond.updateKeeper(keeper.address);
    await tx.wait();
  }
  const keeperWhite = "0xcc1194930B624b94f0365143c18645a329794366";
  if (!(await keeper.isBondWhitelist(keeperWhite))) {
    console.log("Initialize Keeper for bond whitelist");
    const tx = await keeper.updateBondWhitelist([keeperWhite], true);
    await tx.wait();
  }
  if (!(await keeper.isRebaseWhitelist(keeperWhite))) {
    console.log("Initialize Keeper for rebase whitelist");
    const tx = await keeper.updateRebaseWhitelist([keeperWhite], true);
    await tx.wait();
  }

  // setup direct bond
  if ((await directBond.staking()) === constants.AddressZero) {
    console.log("Initialize DirectBondDepositor");
    const tx = await directBond.initialize(staking.address);
    await tx.wait();
  }

  // setup xald
  if ((await xald.staking()) === constants.AddressZero) {
    console.log("Initialize XALD");
    const tx = await xald.initialize(staking.address);
    await tx.wait();
  }

  // setup distributor
  if ((await staking.distributor()) !== distributor.address) {
    console.log("setup distributor in staking");
    const tx = await staking.updateDistributor(distributor.address);
    await tx.wait();
  }

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

  if (await staking.paused()) {
    console.log("unpause staking");
    const tx = await staking.updatePaused(false);
    await tx.wait();
  }

  if (await staking.enableWhitelist()) {
    console.log("disable whitelist in staking");
    const tx = await staking.updateEnableWhitelist(false);
    await tx.wait();
  }

  // setup asset for direct bond
  for (const name of ["WBTC", "WETH", "DAI", "ALDWETH", "ALDUSDC"]) {
    const address = config.tokens[name];
    if (!(await directBond.isBondAsset(address))) {
      console.log("add", name, "to bond");
      const tx = await directBond.updateBondAsset(address, true);
      await tx.wait();
    }
  }

  await deployConvexVault();

  for (const vault of [mimVault, renVault, stethVault, tripoolVault, tricryptoVault]) {
    if (!(await rewardBond.isVault(vault.address))) {
      console.log("add", vault.address, "to reward bond");
      const tx = await rewardBond.updateVault(vault.address, true);
      await tx.wait();
    }
  }

  if ((await treasury.totalReserveUnderlying()).eq(constants.Zero)) {
    console.log("set reserve for treasury");
    const tx = await treasury.updateReserves(
      ethers.utils.parseEther("1500000"),
      ethers.utils.parseEther("0"),
      ethers.utils.parseEther("0")
    );
    await tx.wait();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
