/* eslint-disable node/no-missing-import */
import { RewardBondDepositor, MockERC20, MockStaking, Treasury, MockVault } from "../typechain";
import { MockContract } from "ethereum-waffle";
import { ethers, upgrades } from "hardhat";
import { deployMockForName } from "./mock";
import { BigNumber, constants, ContractFactory, Signer } from "ethers";
import { expect } from "chai";
import { advanceBlockTo } from "./utils";

describe("RewardBondDepositor.spec", async () => {
  let deployer: Signer;
  let dao: Signer;
  let alice: Signer;
  let bob: Signer;

  let ald: MockERC20;
  let token: MockERC20;
  let treasury: Treasury;
  let vault: MockVault;
  let staking: MockStaking;
  let bond: RewardBondDepositor;
  let mockOracle: MockContract;

  beforeEach(async () => {
    [deployer, dao, alice, bob] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20", deployer);
    ald = await MockERC20.deploy("ALD", "ALD", 18);
    await ald.deployed();
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

    const MockStaking = await ethers.getContractFactory("MockStaking", deployer);
    staking = await MockStaking.deploy(ald.address);
    await staking.deployed();

    const RewardBondDepositor = await ethers.getContractFactory("RewardBondDepositor", deployer);
    bond = (await upgrades.deployProxy(RewardBondDepositor as ContractFactory, [
      ald.address,
      treasury.address,
      (await ethers.provider.getBlockNumber()) + 10,
      100,
    ])) as RewardBondDepositor;
    await bond.deployed();

    const MockVault = await ethers.getContractFactory("MockVault", deployer);
    vault = await MockVault.deploy(bond.address, [token.address]);

    await bond.connect(deployer).initializeStaking(staking.address);
    await bond.updateKeeper(await deployer.getAddress());
    await treasury.updateReserveDepositor(bond.address, true);
  });

  it("should revert, when try initialize bond again", async () => {
    await expect(bond.initialize(constants.AddressZero, constants.AddressZero, 0, 0)).to.revertedWith(
      "Initializable: contract is already initialized"
    );
  });

  context("#notify and #bond", async () => {
    it("#notify should revert, when not approved", async () => {
      await expect(bond.notifyRewards(token.address, [ethers.utils.parseEther("1")])).to.revertedWith(
        "RewardBondDepositor: not approved"
      );
    });

    it("#bond should revert, when not approved", async () => {
      await expect(bond.connect(dao).bond(vault.address)).to.revertedWith("RewardBondDepositor: not keeper");
    });

    it("should succeed", async () => {
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await bond.updateVault(vault.address, true);
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);
      const expected = await treasury.bondOf(token.address, ethers.utils.parseEther("10"));
      expect(expected).to.closeToBnR("7895080878992244080", 1, 1000000);

      await token.mint(vault.address, ethers.utils.parseEther("1"));
      await vault.notify(constants.AddressZero, [ethers.utils.parseEther("1")]);

      expect(await bond.rewards(vault.address)).to.eq(true);
      await bond.bond(vault.address);
      expect(await bond.rewards(vault.address)).to.eq(false);

      // about 100 * (pow(2, 0.1) - 1) * 1.1
      expect(await ald.balanceOf(staking.address)).to.eq(expected);
      expect(await treasury.totalReserveVaultReward()).to.eq(ethers.utils.parseEther("10"));
      // about 100 * (pow(2, 0.1) - 1) * 1.1 * 0.05 / 0.95
      expect(await ald.balanceOf(await dao.getAddress())).to.eq(expected.mul(5).div(95));
      expect(await treasury.polReserves(token.address)).to.eq(ethers.utils.parseEther("0.5"));
    });

    it("should calculate share correctly", async () => {
      const epoch0 = await bond.currentEpoch();
      await bond.updateVault(vault.address, true);
      await advanceBlockTo(epoch0.nextBlock.toNumber());
      await bond.rebase();
      const aliceList = [
        BigNumber.from("0"),
        BigNumber.from("10000"),
        BigNumber.from("10100"),
        BigNumber.from("13600"),
      ];
      const bobList = [BigNumber.from("0"), BigNumber.from("0"), BigNumber.from("5000"), BigNumber.from("5050")];
      // 1. alice deposit in epoch 1
      const epoch1 = await bond.currentEpoch();
      await vault.changeBalanceAndNotify(await alice.getAddress(), 100, [0]);
      await advanceBlockTo(epoch1.nextBlock.toNumber());
      await bond.rebase();
      for (let i = 0; i < 2; i++) {
        expect(await bond.getAccountRewardShareSince(i, await alice.getAddress(), vault.address)).to.deep.eq(
          aliceList.slice(i, 2)
        );
        expect(await bond.getAccountRewardShareSince(i, await bob.getAddress(), vault.address)).to.deep.eq(
          bobList.slice(i, 2)
        );
        expect(await bond.rewardShares(i, vault.address)).to.eq(aliceList[i].add(bobList[i]));
      }
      // 2. bob deposit in epoch 2
      const epoch2 = await bond.currentEpoch();
      await vault.changeBalanceAndNotify(await bob.getAddress(), 50, [0]);
      await advanceBlockTo(epoch2.nextBlock.toNumber());
      await bond.rebase();
      for (let i = 0; i < 3; i++) {
        expect(await bond.getAccountRewardShareSince(i, await alice.getAddress(), vault.address)).to.deep.eq(
          aliceList.slice(i, 3)
        );
        expect(await bond.getAccountRewardShareSince(i, await bob.getAddress(), vault.address)).to.deep.eq(
          bobList.slice(i, 3)
        );
        expect(await bond.rewardShares(i, vault.address)).to.eq(aliceList[i].add(bobList[i]));
      }
      // 3. alice deposit twice in epoch 3
      const epoch3 = await bond.currentEpoch();
      await vault.changeBalanceAndNotify(await alice.getAddress(), 10, [0]);
      await advanceBlockTo(epoch3.startBlock.toNumber() + 50);
      await vault.changeBalanceAndNotify(await alice.getAddress(), 50, [0]);
      await advanceBlockTo(epoch3.nextBlock.toNumber());
      await bond.rebase();
      for (let i = 0; i < 4; i++) {
        expect(await bond.getAccountRewardShareSince(i, await alice.getAddress(), vault.address)).to.deep.eq(
          aliceList.slice(i, 4)
        );
        expect(await bond.getAccountRewardShareSince(i, await bob.getAddress(), vault.address)).to.deep.eq(
          bobList.slice(i, 4)
        );
        expect(await bond.rewardShares(i, vault.address)).to.eq(aliceList[i].add(bobList[i]));
      }
      // 4. alice deposit in epoch 4
      await vault.changeBalanceAndNotify(await alice.getAddress(), 50, [0]);
      for (let i = 0; i < 4; i++) {
        expect(await bond.getAccountRewardShareSince(i, await alice.getAddress(), vault.address)).to.deep.eq(
          aliceList.slice(i, 4)
        );
        expect(await bond.getAccountRewardShareSince(i, await bob.getAddress(), vault.address)).to.deep.eq(
          bobList.slice(i, 4)
        );
        expect(await bond.rewardShares(i, vault.address)).to.eq(aliceList[i].add(bobList[i]));
      }
    });
  });
});
