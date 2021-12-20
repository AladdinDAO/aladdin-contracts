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
import { ethers, upgrades } from "hardhat";
import { deployMockForName } from "./mock";
import { BigNumber, constants, Signer } from "ethers";
import { expect } from "chai";
import { advanceBlockTo } from "./utils";

describe("RewardBondDepositor.spec", async () => {
  let deployer: Signer;
  let dao: Signer;
  let alice: Signer;
  let bob: Signer;
  let keeper: Signer;

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
    [deployer, dao, alice, bob, keeper] = await ethers.getSigners();

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
    rewardBond = (await upgrades.deployProxy(RewardBondDepositor, [
      ald.address,
      treasury.address,
      (await ethers.provider.getBlockNumber()) + 3,
      100,
    ])) as RewardBondDepositor;
    await rewardBond.deployed();

    const DirectBondDepositor = await ethers.getContractFactory("DirectBondDepositor", deployer);
    directBond = await DirectBondDepositor.deploy(ald.address, treasury.address);
    await directBond.deployed();

    const Staking = await ethers.getContractFactory("Staking", deployer);
    staking = (await upgrades.deployProxy(Staking, [
      ald.address,
      xald.address,
      wxald.address,
      rewardBond.address,
    ])) as Staking;
    await staking.deployed();
    await staking.updateDefaultLockingPeriod(6);

    const Distributor = await ethers.getContractFactory("Distributor", deployer);
    distributor = await Distributor.deploy(ald.address, treasury.address, staking.address);
    await distributor.deployed();
    await distributor.updateRewardRate(ethers.utils.parseEther("0.3"));

    const MockVault = await ethers.getContractFactory("MockVault", deployer);
    vault = await MockVault.deploy(rewardBond.address, [token.address]);

    await rewardBond.initializeStaking(staking.address);
    await directBond.initialize(staking.address);
    await xald.initialize(staking.address);
    await staking.updateDistributor(distributor.address);
    await staking.updateDirectBondDepositor(directBond.address);
    await rewardBond.updateKeeper(await deployer.getAddress());
    await treasury.updateRewardManager(distributor.address, true);
    await treasury.updateReserveDepositor(rewardBond.address, true);
    await treasury.updateReserveDepositor(directBond.address, true);
  });

  it("should revert, when try initialize staking again", async () => {
    await expect(
      staking.initialize(constants.AddressZero, constants.AddressZero, constants.AddressZero, constants.AddressZero)
    ).to.revertedWith("Initializable: contract is already initialized");
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
      await directBond.connect(alice).deposit(token.address, ethers.utils.parseEther("1"), expected);

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

    it("should calculate every thing correctly, only 1 vault", async () => {
      await staking.updatePaused(false);
      await rewardBond.updateVault(vault.address, true);
      await token.mint(vault.address, ethers.utils.parseEther("10000"));
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);

      // 1. alice deposit in epoch 0
      const epoch0 = await rewardBond.currentEpoch();
      await vault.changeBalanceAndNotify(await alice.getAddress(), ethers.utils.parseEther("100"), [
        ethers.utils.parseEther("0"),
      ]);
      // 2. harvest and bond at the end of epoch 0
      await vault.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
        ethers.utils.parseEther("10"),
      ]);
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await advanceBlockTo(epoch0.nextBlock.toNumber());
      const expected0 = await treasury.bondOf(token.address, ethers.utils.parseEther("10"));
      const supplyBefore0 = (await ald.totalSupply()).add(expected0);
      await rewardBond.rebase();
      const supplyAfter0 = await ald.totalSupply();
      expect(supplyAfter0).to.eq(supplyBefore0.mul(13).div(10));
      const totalXALD0 = expected0.add(supplyBefore0.mul(3).div(10));
      expect(await staking.pendingXALD(await alice.getAddress())).to.eq(totalXALD0);
      expect(await staking.pendingXALDByVault(await alice.getAddress(), vault.address)).to.eq(totalXALD0);
      expect(await staking.unlockedXALD(await alice.getAddress())).to.closeToBn(totalXALD0.div(250), 1000);
      expect(await staking.unlockedXALDByVault(await alice.getAddress(), vault.address)).to.closeToBn(
        totalXALD0.div(250),
        1000
      );
      // 3. bob deposit in epoch 1
      const epoch1 = await rewardBond.currentEpoch();
      await advanceBlockTo(epoch1.startBlock.toNumber() + 10);
      await vault.changeBalanceAndNotify(await bob.getAddress(), ethers.utils.parseEther("50"), [
        ethers.utils.parseEther("0"),
      ]);
      // 4. harvest and bond at the end of epoch 1
      await vault.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
        ethers.utils.parseEther("10"),
      ]);
      await advanceBlockTo(epoch1.nextBlock.toNumber());
      const expected1 = await treasury.bondOf(token.address, ethers.utils.parseEther("10"));
      const supplyBefore1 = (await ald.totalSupply()).add(expected1);
      await rewardBond.rebase();
      const supplyAfter1 = await ald.totalSupply();
      expect(supplyAfter1).to.eq(supplyBefore1.mul(13).div(10));
      // total share in epoch 1 = 100 * 101 (alice) + 50 * 90 (bob)
      // alice xald before rebase should totalXALD0 + expected1 * 101 / 146
      // bob xald before rebase should expected1 * 45 / 146
      const reward1 = supplyBefore1.mul(3).div(10);
      const aliceXALDBefore1 = totalXALD0.add(expected1.mul(101).div(146));
      const bobXALDBefore1 = expected1.mul(45).div(146);
      const aliceXALDAfter1 = aliceXALDBefore1.add(
        reward1.mul(aliceXALDBefore1).div(bobXALDBefore1.add(aliceXALDBefore1))
      );
      const bobXALDAfter1 = bobXALDBefore1.add(reward1.mul(bobXALDBefore1).div(bobXALDBefore1.add(aliceXALDBefore1)));
      expect(await staking.pendingXALD(await alice.getAddress())).to.closeToBn(aliceXALDAfter1, 1000);
      expect(await staking.pendingXALDByVault(await alice.getAddress(), vault.address)).to.closeToBn(
        aliceXALDAfter1,
        1000
      );
      expect(await staking.pendingXALD(await bob.getAddress())).to.closeToBn(bobXALDAfter1, 1000);
      expect(await staking.pendingXALDByVault(await bob.getAddress(), vault.address)).closeToBn(bobXALDAfter1, 1000);
      expect(await staking.unlockedXALD(await bob.getAddress())).to.closeToBn(bobXALDAfter1.div(250), 1000);
      expect(await staking.unlockedXALDByVault(await bob.getAddress(), vault.address)).to.closeToBn(
        bobXALDAfter1.div(250),
        1000
      );
      // 5. alice claim in epoch 2
      await staking.connect(alice).redeem(await alice.getAddress(), false);
      const claimed = await xald.balanceOf(await alice.getAddress());
      const pending = await staking.pendingXALD(await alice.getAddress());
      expect(claimed.add(pending)).to.closeToBn(aliceXALDAfter1, 1000);
    });

    it("should calculate every thing correctly, with multiple vaults", async () => {
      const MockVault = await ethers.getContractFactory("MockVault", deployer);
      const vault2 = await MockVault.deploy(rewardBond.address, [token.address]);

      await staking.updatePaused(false);
      await rewardBond.updateVault(vault.address, true);
      await rewardBond.updateVault(vault2.address, true);

      await token.mint(vault.address, ethers.utils.parseEther("10000"));
      await token.mint(vault2.address, ethers.utils.parseEther("10000"));
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);
      // no reward for easy calculating
      await staking.updateDistributor(constants.AddressZero);

      // 1. alice deposit vault1 in epoch 0
      const epoch0 = await rewardBond.currentEpoch();
      await vault.changeBalanceAndNotify(await alice.getAddress(), ethers.utils.parseEther("100"), [
        ethers.utils.parseEther("0"),
      ]);
      // 2. harvest and bond at the end of epoch 0
      await vault.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
        ethers.utils.parseEther("10"),
      ]);
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await advanceBlockTo(epoch0.nextBlock.toNumber());
      const expectedVault1InEpoch0 = await treasury.bondOf(token.address, ethers.utils.parseEther("10"));
      const supplyBefore0 = (await ald.totalSupply()).add(expectedVault1InEpoch0);
      await rewardBond.rebase();
      const supplyAfter0 = await ald.totalSupply();
      expect(supplyAfter0).to.eq(supplyBefore0);
      const totalXALD0 = expectedVault1InEpoch0;
      expect(await staking.pendingXALD(await alice.getAddress())).to.eq(totalXALD0);
      expect(await staking.pendingXALDByVault(await alice.getAddress(), vault.address)).to.eq(totalXALD0);
      expect(await staking.unlockedXALD(await alice.getAddress())).to.closeToBn(totalXALD0.div(250), 1000);
      expect(await staking.unlockedXALDByVault(await alice.getAddress(), vault.address)).to.closeToBn(
        totalXALD0.div(250),
        1000
      );
      // 3. bob deposit in vault1 and alice deposit in vault 2, in epoch 1
      const epoch1 = await rewardBond.currentEpoch();
      await advanceBlockTo(epoch1.startBlock.toNumber() + 10);
      await vault.changeBalanceAndNotify(await bob.getAddress(), ethers.utils.parseEther("50"), [
        ethers.utils.parseEther("0"),
      ]);
      await vault2.changeBalanceAndNotify(await alice.getAddress(), ethers.utils.parseEther("50"), [
        ethers.utils.parseEther("0"),
      ]);
      // 4. harvest and bond at the end of epoch 1
      await vault.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
        ethers.utils.parseEther("10"),
      ]);
      await vault2.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
        ethers.utils.parseEther("10"),
      ]);
      await advanceBlockTo(epoch1.nextBlock.toNumber());
      await rewardBond.rebase();

      const pendingAliceInEpoch1 = await staking.pendingXALD(await alice.getAddress());
      const pendingAliceVault1InEpoch1 = await staking.pendingXALDByVault(await alice.getAddress(), vault.address);
      const pendingAliceVault2InEpoch1 = await staking.pendingXALDByVault(await alice.getAddress(), vault2.address);
      const unlockedAliceInEpoch1 = await staking.unlockedXALD(await alice.getAddress());
      const unlockedAliceVault1InEpoch1 = await staking.unlockedXALDByVault(await alice.getAddress(), vault.address);
      const unlockedAliceVault2InEpoch1 = await staking.unlockedXALDByVault(await alice.getAddress(), vault2.address);
      expect(pendingAliceInEpoch1).to.eq(pendingAliceVault1InEpoch1.add(pendingAliceVault2InEpoch1));
      expect(unlockedAliceInEpoch1).to.eq(unlockedAliceVault1InEpoch1.add(unlockedAliceVault2InEpoch1));

      const pendingBobInEpoch1 = await staking.pendingXALD(await bob.getAddress());
      const pendingBobVault1InEpoch1 = await staking.pendingXALDByVault(await bob.getAddress(), vault.address);
      const pendingBobVault2InEpoch1 = await staking.pendingXALDByVault(await bob.getAddress(), vault2.address);
      const unlockedBobInEpoch1 = await staking.unlockedXALD(await bob.getAddress());
      const unlockedBobVault1InEpoch1 = await staking.unlockedXALDByVault(await bob.getAddress(), vault.address);
      const unlockedBobVault2InEpoch1 = await staking.unlockedXALDByVault(await bob.getAddress(), vault2.address);
      expect(pendingBobInEpoch1).to.eq(pendingBobVault1InEpoch1.add(pendingBobVault2InEpoch1));
      expect(unlockedBobInEpoch1).to.eq(unlockedBobVault1InEpoch1.add(unlockedBobVault2InEpoch1));
      expect(pendingBobVault2InEpoch1).to.eq(constants.Zero);

      // 5. alice claim in epoch 2
      const epoch2 = await rewardBond.currentEpoch();
      await staking.connect(alice).redeem(await alice.getAddress(), false);
      const claimed = await xald.balanceOf(await alice.getAddress());
      const pendingAliceInEpoch2 = await staking.pendingXALD(await alice.getAddress());
      const pendingAliceVault1InEpoch2 = await staking.pendingXALDByVault(await alice.getAddress(), vault.address);
      const pendingAliceVault2InEpoch2 = await staking.pendingXALDByVault(await alice.getAddress(), vault2.address);
      expect(claimed.add(pendingAliceInEpoch2)).to.closeToBn(pendingAliceInEpoch1, 1000);
      expect(pendingAliceInEpoch2).to.eq(pendingAliceVault1InEpoch2.add(pendingAliceVault2InEpoch2));

      // 6. harvest and bond at the end of epoch 2
      await vault.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
        ethers.utils.parseEther("10"),
      ]);
      await vault2.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
        ethers.utils.parseEther("10"),
      ]);
      await advanceBlockTo(epoch2.nextBlock.toNumber());
      await rewardBond.rebase();

      // 7. alice exit all asset from vault 1
      await vault.changeBalanceAndNotify(await alice.getAddress(), ethers.utils.parseEther("-100"), [
        ethers.utils.parseEther("0"),
      ]);
      // 8. harvest and bond at the end of epoch 3,4,5
      for (let _ = 0; _ < 3; ++_) {
        const epoch3 = await rewardBond.currentEpoch();
        await vault.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
          ethers.utils.parseEther("10"),
        ]);
        await vault2.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
          ethers.utils.parseEther("10"),
        ]);
        await advanceBlockTo(epoch3.nextBlock.toNumber());
        await rewardBond.rebase();

        const pendingAliceInEpoch3 = await staking.pendingXALD(await alice.getAddress());
        const pendingBobInEpoch3 = await staking.pendingXALD(await bob.getAddress());
        const pendingAliceVault1InEpoch3 = await staking.pendingXALDByVault(await alice.getAddress(), vault.address);
        const pendingAliceVault2InEpoch3 = await staking.pendingXALDByVault(await alice.getAddress(), vault2.address);
        const unlockedAliceInEpoch3 = await staking.unlockedXALD(await alice.getAddress());
        const unlockedAliceVault1InEpoch3 = await staking.unlockedXALDByVault(await alice.getAddress(), vault.address);
        const unlockedAliceVault2InEpoch3 = await staking.unlockedXALDByVault(await alice.getAddress(), vault2.address);
        expect(pendingAliceInEpoch3).to.eq(pendingAliceVault1InEpoch3.add(pendingAliceVault2InEpoch3));
        expect(unlockedAliceInEpoch3).to.eq(unlockedAliceVault1InEpoch3.add(unlockedAliceVault2InEpoch3));
        const wxaldBalance = await wxald.balanceOf(staking.address);
        const xaldBalance = await wxald.wrappedXALDToXALD(wxaldBalance);
        expect(pendingAliceInEpoch3.add(pendingBobInEpoch3)).to.closeToBn(xaldBalance, 1000);
      }
      // 9. redeem, harvest and bond at the end of epoch 6,7,8
      for (let _ = 0; _ < 3; ++_) {
        await staking.connect(alice).redeem(await alice.getAddress(), false);
        await staking.connect(bob).redeem(await bob.getAddress(), false);
        const epoch3 = await rewardBond.currentEpoch();
        await vault.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
          ethers.utils.parseEther("10"),
        ]);
        await vault2.changeBalanceAndNotify(await keeper.getAddress(), ethers.utils.parseEther("0"), [
          ethers.utils.parseEther("10"),
        ]);
        await advanceBlockTo(epoch3.nextBlock.toNumber());
        await rewardBond.rebase();

        const pendingAliceInEpoch3 = await staking.pendingXALD(await alice.getAddress());
        const pendingBobInEpoch3 = await staking.pendingXALD(await bob.getAddress());
        const pendingAliceVault1InEpoch3 = await staking.pendingXALDByVault(await alice.getAddress(), vault.address);
        const pendingAliceVault2InEpoch3 = await staking.pendingXALDByVault(await alice.getAddress(), vault2.address);
        const unlockedAliceInEpoch3 = await staking.unlockedXALD(await alice.getAddress());
        const unlockedAliceVault1InEpoch3 = await staking.unlockedXALDByVault(await alice.getAddress(), vault.address);
        const unlockedAliceVault2InEpoch3 = await staking.unlockedXALDByVault(await alice.getAddress(), vault2.address);
        expect(pendingAliceInEpoch3).to.eq(pendingAliceVault1InEpoch3.add(pendingAliceVault2InEpoch3));
        expect(unlockedAliceInEpoch3).to.eq(unlockedAliceVault1InEpoch3.add(unlockedAliceVault2InEpoch3));
        const wxaldBalance = await wxald.balanceOf(staking.address);
        const xaldBalance = await wxald.wrappedXALDToXALD(wxaldBalance);
        expect(pendingAliceInEpoch3.add(pendingBobInEpoch3)).to.closeToBn(xaldBalance, 1000);
      }
    });
  });
});
