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
};

const uniswapETHPairs: { [name: string]: string } = {
  CVX: "0x05767d9EF41dC40689678fFca0608878fb3dE906",
  LDO: "0xC558F600B34A5f69dD2f0D06Cb8A88d829B7420a",
};

const discount: { [name: string]: BigNumber } = {
  WBTC: ethers.utils.parseEther("1.1"),
  WETH: ethers.utils.parseEther("1.1"),
  SPELL: ethers.utils.parseEther("1.1"),
  CRV: ethers.utils.parseEther("1.1"),
  CVX: ethers.utils.parseEther("1.1"),
  LDO: ethers.utils.parseEther("1.1"),
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
  };
  rewardBond?: string;
  directBond?: string;
  staking?: string;
  distributor?: string;
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
    WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    WBTC: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
    USDC: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    CRV: "0xD533a949740bb3306d119CC777fa900bA034cd52",
    CVX: "0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B",
    LDO: "0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32",
    SPELL: "0x090185f2135308BaD17527004364eBcC2D37e5F6",
  },
  dao: "0xB5495A8D85EE18cfD0d2816993658D88aF08bEF4",
  ald: "0x272bFF6ff60a2D614e654ba06AC4A7422630AdE3",
  xald: "0xb13B85363A25c7361877EebaEcCed99e353F2aF9",
  wxald: "0xBDC423927e70E4013A7906FE54ad8209643f734C",
  treasury: "0x5aa403275cdf5a487D195E8306FD0628D4F5747B",
  oracles: {
    chainlink: "0x1c0E5Eb9F91A58FCE9F4731a88b3e14f9961482e",
    uniswapETH: "0x4BAbB3f39718C4567d27aF42A02e8CAF560df85e",
  },
  rewardBond: "0xCc1034754684A1E688DFDf90E7a859B266f734ec",
  directBond: "0x71E60b439c533b09cB23dd2BCd439A8c337A5C97",
  staking: "0x46Be096eC3F3b51DfFC1B694789D2c6765f3BD29",
  distributor: "0xfe8423705161028451757819c4099044459eae88",
  vaults: {
    convex: {
      mim: "0xBA6a5b4294ceEdC0Fbc1485fCd513f5A8565774b",
      ren: "0x5d3387FF435A9D684C4b8c84FC27d2f1a3729b42",
      steth: "0x0C23171Ee3794643F7B3C15B66b9878874AA47AA",
      tricrypto: "0x6cd06c8a609E29a74c865dA5494dafD82D51658b",
      tripool: "0x5A642D1Ff7925f4D609acA214Dd123A5E38688D0",
    },
  },
};

let ald: MockERC20;
let xald: XALD;
let wxald: WrappedXALD;
let treasury: Treasury;
let chainlink: ChainlinkPriceOracle;
let uniswapETH: UniswapV2PriceOracle;
let rewardBond: RewardBondDepositor;
let directBond: DirectBondDepositor;
let staking: Staking;
let distributor: Distributor;

let mimVault: MIMConvexVault;
let renVault: RenConvexVault;
let stethVault: STETHConvexVault;
let tricryptoVault: TriCrypto2ConvexVault;
let tripoolVault: TriPoolConvexVault;

async function setupReserveToken() {
  // setup reserve tokens
  for (const name of ["WBTC", "WETH", "CRV", "SPELL", "LDO", "CVX"]) {
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
}

async function setupOracle() {
  // setup chainlink oracle
  for (const name of ["WBTC", "WETH", "CRV", "SPELL"]) {
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

  // setup reward bond
  if ((await rewardBond.staking()) === constants.AddressZero) {
    console.log("Initialize RewardBondDepositor");
    const tx = await rewardBond.initialize(staking.address);
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
  for (const name of ["WBTC", "WETH"]) {
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
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
