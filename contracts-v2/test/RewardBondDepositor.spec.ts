/* eslint-disable node/no-missing-import */
import { RewardBondDepositor, MockERC20, MockStaking, Treasury, MockVault } from "../typechain";
import { MockContract } from "ethereum-waffle";
import { ethers } from "hardhat";
import { deployMockForName } from "./mock";
import "./utils";
import { constants, Signer } from "ethers";
import { expect } from "chai";

describe("RewardBondDepositor.spec", async () => {
  let deployer: Signer;
  let dao: Signer;

  let ald: MockERC20;
  let token: MockERC20;
  let treasury: Treasury;
  let vault: MockVault;
  let staking: MockStaking;
  let bond: RewardBondDepositor;
  let mockOracle: MockContract;

  beforeEach(async () => {
    [deployer, dao] = await ethers.getSigners();

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
    bond = await RewardBondDepositor.deploy(ald.address, treasury.address, 100);
    await bond.deployed();

    const MockVault = await ethers.getContractFactory("MockVault", deployer);
    vault = await MockVault.deploy(bond.address, [token.address]);

    await bond.initialize(staking.address);
    await bond.updateKeeper(await deployer.getAddress());
    await treasury.updateReserveDepositor(bond.address, true);
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
  });
});
