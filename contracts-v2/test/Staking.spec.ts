/* eslint-disable node/no-missing-import */
import {
  RewardBondDepositor,
  MockERC20,
  Treasury,
  MockVault,
  Staking,
  DirectBondDepositor,
  XALD,
  WrappedXALD,
  Distributor,
} from "../typechain";
import { MockContract } from "ethereum-waffle";
import { ethers } from "hardhat";
import { deployMockForName } from "./mock";
import { BigNumber, constants, Signer } from "ethers";
import { expect } from "chai";
import { advanceBlockTo } from "./utils";

describe("RewardBondDepositor.spec", async () => {
  let deployer: Signer;
  let dao: Signer;
  let alice: Signer;

  let ald: MockERC20;
  let xald: XALD;
  let wxald: WrappedXALD;
  let token: MockERC20;
  let treasury: Treasury;
  let vault: MockVault;
  let staking: Staking;
  let distributor: Distributor;
  let directBond: DirectBondDepositor;
  let rewardBond: RewardBondDepositor;
  let mockOracle: MockContract;

  beforeEach(async () => {
    [deployer, dao, alice] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20", deployer);
    ald = await MockERC20.deploy("ALD", "ALD", 18);
    await ald.deployed();

    const XALD = await ethers.getContractFactory("XALD", deployer);
    xald = await XALD.deploy();
    await xald.deployed();

    const WrappedXALD = await ethers.getContractFactory("WrappedXALD", deployer);
    wxald = await WrappedXALD.deploy(xald.address);
    await wxald.deployed();

    token = await MockERC20.deploy("token", "token", 18);
    await token.deployed();

    await token.mint(await deployer.getAddress(), ethers.utils.parseEther("100"));
    await ald.mint(await deployer.getAddress(), ethers.utils.parseEther("100"));

    const Treasury = await ethers.getContractFactory("Treasury", deployer);
    treasury = await Treasury.deploy(ald.address, await dao.getAddress());
    await treasury.deployed();

    mockOracle = await deployMockForName(deployer, "IPriceOracle");
    await treasury.updateReserveToken(token.address, true);
    await treasury.updatePriceOracle(token.address, mockOracle.address);
    await treasury.updateDiscount(token.address, "1100000000000000000"); // 110%
    await treasury.updatePercentagePOL(token.address, "500000000000000000"); // 50%
    await treasury.updatePercentageContributor(0); // make it zero

    const RewardBondDepositor = await ethers.getContractFactory("RewardBondDepositor", deployer);
    rewardBond = await RewardBondDepositor.deploy(ald.address, treasury.address, 100);
    await rewardBond.deployed();

    const DirectBondDepositor = await ethers.getContractFactory("DirectBondDepositor", deployer);
    directBond = await DirectBondDepositor.deploy(ald.address, treasury.address);
    await directBond.deployed();

    const Staking = await ethers.getContractFactory("Staking", deployer);
    staking = await Staking.deploy(ald.address, xald.address, wxald.address, directBond.address, rewardBond.address);
    await staking.deployed();
    await staking.updateDefaultLockingPeriod(6);

    const Distributor = await ethers.getContractFactory("Distributor", deployer);
    distributor = await Distributor.deploy(ald.address, treasury.address, staking.address);
    await distributor.deployed();

    const MockVault = await ethers.getContractFactory("MockVault", deployer);
    vault = await MockVault.deploy(rewardBond.address, [token.address]);

    await rewardBond.initialize(staking.address);
    await directBond.initialize(staking.address);
    await xald.initialize(staking.address);
    await staking.updateDistributor(distributor.address);
    await rewardBond.updateKeeper(await deployer.getAddress());
    await treasury.updateRewardManager(distributor.address, true);
    await treasury.updateReserveDepositor(rewardBond.address, true);
    await treasury.updateReserveDepositor(directBond.address, true);
  });

  context("#stake and #unstake", async () => {
    it("should revert when paused", async () => {
      await expect(staking.stake(constants.Zero)).to.revertedWith("Staking: paused");
      await expect(staking.stakeAll()).to.revertedWith("Staking: paused");
      await expect(staking.stakeFor(constants.AddressZero, constants.Zero)).to.revertedWith("Staking: paused");
    });

    it("should revert when not whitelist call", async () => {
      await staking.updatePaused(false);
      await expect(staking.stake(constants.Zero)).to.revertedWith("Staking: not whitelist");
      await expect(staking.stakeAll()).to.revertedWith("Staking: not whitelist");
      await expect(staking.stakeFor(constants.AddressZero, constants.Zero)).to.revertedWith("Staking: not whitelist");
    });

    it("should succeed", async () => {
      await staking.updatePaused(false);
      await staking.updateEnableWhitelist(false);

      // alice stake 10 ald
      await ald.mint(await alice.getAddress(), ethers.utils.parseEther("10"));
      await ald.connect(alice).approve(staking.address, ethers.utils.parseEther("10"));
      await staking.connect(alice).stake(ethers.utils.parseEther("10"));
      expect(await staking.pendingXALD(await alice.getAddress())).to.eq(ethers.utils.parseEther("10"));
      expect(await staking.unlockedXALD(await alice.getAddress())).to.eq(constants.Zero);

      // rebase
      const epoch = await rewardBond.currentEpoch();
      await advanceBlockTo(epoch.nextBlock.toNumber());
      const supplyBefore = await ald.totalSupply();
      await rewardBond.rebase();
      const supplyAfter = await ald.totalSupply();
      expect(supplyAfter).to.eq(supplyBefore.add(supplyBefore.mul(3).div(10)));

      expect(await staking.pendingXALD(await alice.getAddress())).to.eq(ethers.utils.parseEther("43"));
      expect(await staking.unlockedXALD(await alice.getAddress())).to.eq(BigNumber.from("143333333333333331"));

      // redeem
      await staking.connect(alice).redeem(await alice.getAddress(), false);
      expect(await xald.balanceOf(await alice.getAddress())).to.eq(BigNumber.from("215000000000000000"));

      // unstake
      await staking.connect(alice).unstake(await alice.getAddress(), BigNumber.from("100000000000000000"));
      expect(await xald.balanceOf(await alice.getAddress())).to.eq(BigNumber.from("115000000000000000"));
      expect(await ald.balanceOf(await alice.getAddress())).to.eq(BigNumber.from("100000000000000000"));
    });
  });

  context("#bondFor and #unstake", async () => {
    it("should succeed", async () => {
      await staking.updatePaused(false);
      await directBond.updateBondAsset(token.address, true);

      // alice bond
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);
      const expected = await directBond.getBondALD(token.address, ethers.utils.parseEther("1"));
      expect(expected).to.closeToBnR("7895080878992244080", 1, 1000000);

      await token.mint(await alice.getAddress(), ethers.utils.parseEther("1"));
      await token.connect(alice).approve(directBond.address, ethers.utils.parseEther("1"));
      await directBond.connect(alice).deposit(token.address, ethers.utils.parseEther("1"));

      expect(await staking.pendingXALD(await alice.getAddress())).to.eq(expected);
      expect(await staking.unlockedXALD(await alice.getAddress())).to.eq(constants.Zero);

      // rebase
      const epoch = await rewardBond.currentEpoch();
      await advanceBlockTo(epoch.nextBlock.toNumber());
      const supplyBefore = await ald.totalSupply();
      await rewardBond.rebase();
      const supplyAfter = await ald.totalSupply();
      expect(supplyAfter).to.eq(supplyBefore.add(supplyBefore.mul(3).div(10)));

      const pending = expected.add(supplyBefore.mul(3).div(10));
      expect(await staking.pendingXALD(await alice.getAddress())).to.eq(pending);
      expect(await staking.unlockedXALD(await alice.getAddress())).to.closeToBn(pending.mul(2).div(100 * 5), 100);

      // redeem
      await staking.connect(alice).redeem(await alice.getAddress(), false);
      expect(await xald.balanceOf(await alice.getAddress())).to.closeToBn(pending.mul(3).div(100 * 5), 100);

      // unstake
      const unstake = pending.mul(3).div(100 * 5);
      await staking.connect(alice).unstake(await alice.getAddress(), unstake.div(3));
      expect(await xald.balanceOf(await alice.getAddress())).to.closeToBn(unstake.sub(unstake.div(3)), 100);
      expect(await ald.balanceOf(await alice.getAddress())).to.eq(unstake.div(3));
    });
  });

  context("#rewardBond and #unstake", async () => {
    it("should succeed", async () => {
      await staking.updatePaused(false);
      await rewardBond.updateVault(vault.address, true);

      // alice bond
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);
      const expected = await treasury.bondOf(token.address, ethers.utils.parseEther("10"));
      expect(expected).to.closeToBnR("7895080878992244080", 1, 1000000);

      await token.mint(vault.address, ethers.utils.parseEther("1"));
      await vault.addBalance(await alice.getAddress(), ethers.utils.parseEther("1"));
      await vault.notify(await alice.getAddress(), [ethers.utils.parseEther("1")]);

      // rebase
      const epoch = await rewardBond.currentEpoch();
      await advanceBlockTo(epoch.nextBlock.toNumber());
      const supplyBefore = (await ald.totalSupply()).add(expected);
      await rewardBond.rebase();
      const supplyAfter = await ald.totalSupply();
      expect(supplyAfter).to.eq(supplyBefore.mul(13).div(10));

      const pending = expected.add(supplyBefore.mul(3).div(10));
      expect(await staking.pendingXALD(await alice.getAddress())).to.eq(pending);
      expect(await staking.unlockedXALD(await alice.getAddress())).to.closeToBn(pending.mul(2).div(100 * 5), 100);

      // redeem
      await staking.connect(alice).redeem(await alice.getAddress(), false);
      expect(await xald.balanceOf(await alice.getAddress())).to.closeToBn(pending.mul(3).div(100 * 5), 100);

      // unstake
      const unstake = pending.mul(3).div(100 * 5);
      await staking.connect(alice).unstake(await alice.getAddress(), unstake.div(3));
      expect(await xald.balanceOf(await alice.getAddress())).to.closeToBn(unstake.sub(unstake.div(3)), 100);
      expect(await ald.balanceOf(await alice.getAddress())).to.eq(unstake.div(3));
    });
  });
});
