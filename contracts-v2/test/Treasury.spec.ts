/* eslint-disable node/no-missing-import */
import { MockERC20, Treasury } from "../typechain";
import { MockContract } from "ethereum-waffle";
import { ethers } from "hardhat";
import { deployMockForName } from "./mock";
import "./utils";
import { constants, Signer } from "ethers";
import { expect } from "chai";

describe("Treasury.spec", async () => {
  let deployer: Signer;
  let dao: Signer;
  let depositor: Signer;

  let ald: MockERC20;
  let token: MockERC20;
  let treasury: Treasury;
  let mockOracle: MockContract;

  beforeEach(async () => {
    [deployer, dao, depositor] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20", deployer);
    ald = await MockERC20.deploy("ALD", "ALD", 18);
    await ald.deployed();
    token = await MockERC20.deploy("token", "token", 18);
    await token.deployed();

    const Treasury = await ethers.getContractFactory("Treasury", deployer);
    treasury = await Treasury.deploy(ald.address, await dao.getAddress());
    await treasury.deployed();

    mockOracle = await deployMockForName(deployer, "IPriceOracle");
    await treasury.updatePriceOracle(token.address, mockOracle.address);
    await treasury.updateDiscount(token.address, "1100000000000000000"); // 110%
    await treasury.updatePercentagePOL(token.address, "500000000000000000"); // 50%
    await token.mint(await depositor.getAddress(), ethers.utils.parseEther("100"));
    await ald.mint(await deployer.getAddress(), ethers.utils.parseEther("100"));
  });

  context("#deposit", async () => {
    it("should revert, when token not approved", async () => {
      await expect(treasury.deposit(0, token.address, ethers.utils.parseEther("1"))).to.revertedWith(
        "Treasury: not accepted"
      );
    });
    it("should revert, when non depositor deposit", async () => {
      await treasury.updateReserveToken(token.address, true);
      await expect(treasury.deposit(0, token.address, ethers.utils.parseEther("1"))).to.revertedWith(
        "Treasury: not approved depositor"
      );
    });

    it("should succeed when deposit underlying", async () => {
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);
      await treasury.updateReserveToken(token.address, true);
      await treasury.updateReserveDepositor(await depositor.getAddress(), true);
      await token.connect(depositor).approve(treasury.address, ethers.utils.parseEther("1"));
      await treasury.connect(depositor).deposit(1, token.address, ethers.utils.parseEther("1"));
      // about 100 * (pow(2, 0.1) - 1) * 1.1
      expect(await ald.balanceOf(await depositor.getAddress())).to.closeToBnR("7895080878992244080", 1, 1000000);
      expect(await treasury.totalReserveUnderlying()).to.eq(ethers.utils.parseEther("20"));
      // about 100 * (pow(2, 0.1) - 1) * 1.1 * 0.05 / 0.95
      expect(await ald.balanceOf(await dao.getAddress())).to.closeToBnR("415530572578539162", 1, 1000000);
      expect(await treasury.polReserves(token.address)).to.eq(ethers.utils.parseEther("0.5"));
    });

    it("should succeed when deposit vault reward", async () => {
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);
      await treasury.updateReserveToken(token.address, true);
      await treasury.updateReserveDepositor(await depositor.getAddress(), true);
      await token.connect(depositor).approve(treasury.address, ethers.utils.parseEther("1"));
      await treasury.connect(depositor).deposit(2, token.address, ethers.utils.parseEther("1"));
      // about 100 * (pow(2, 0.1) - 1) * 1.1
      expect(await ald.balanceOf(await depositor.getAddress())).to.closeToBnR("7895080878992244080", 1, 1000000);
      expect(await treasury.totalReserveVaultReward()).to.eq(ethers.utils.parseEther("10"));
      // about 100 * (pow(2, 0.1) - 1) * 1.1 * 0.05 / 0.95
      expect(await ald.balanceOf(await dao.getAddress())).to.closeToBnR("415530572578539162", 1, 1000000);
      expect(await treasury.polReserves(token.address)).to.eq(ethers.utils.parseEther("0.5"));
    });

    it("should succeed when deposit liquidity token", async () => {
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);
      await treasury.updateReserveToken(token.address, true);
      await treasury.updateReserveDepositor(await depositor.getAddress(), true);
      await token.connect(depositor).approve(treasury.address, ethers.utils.parseEther("1"));
      await treasury.connect(depositor).deposit(3, token.address, ethers.utils.parseEther("1"));
      // about 100 * (pow(2, 0.1) - 1) * 1.1
      expect(await ald.balanceOf(await depositor.getAddress())).to.closeToBnR("7895080878992244080", 1, 1000000);
      expect(await treasury.totalReserveLiquidityToken()).to.eq(ethers.utils.parseEther("10"));
      // about 100 * (pow(2, 0.1) - 1) * 1.1 * 0.05 / 0.95
      expect(await ald.balanceOf(await dao.getAddress())).to.closeToBnR("415530572578539162", 1, 1000000);
      expect(await treasury.polReserves(token.address)).to.eq(ethers.utils.parseEther("0.5"));
    });

    it("should succeed when deposit null", async () => {
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await treasury.updateReserveToken(token.address, true);
      await treasury.updateReserveDepositor(await depositor.getAddress(), true);
      await token.connect(depositor).approve(treasury.address, ethers.utils.parseEther("1"));
      await treasury.connect(depositor).deposit(0, token.address, ethers.utils.parseEther("1"));
      expect(await ald.balanceOf(await depositor.getAddress())).to.eq(constants.Zero);
      expect(await treasury.totalReserveLiquidityToken()).to.eq(constants.Zero);
      expect(await ald.balanceOf(await dao.getAddress())).to.eq(constants.Zero);
      expect(await treasury.polReserves(token.address)).to.eq(constants.Zero);
    });

    it("should revert when deposit not supported", async () => {
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await treasury.updateReserveToken(token.address, true);
      await treasury.updateReserveDepositor(await depositor.getAddress(), true);
      await token.connect(depositor).approve(treasury.address, ethers.utils.parseEther("1"));
      await expect(treasury.connect(depositor).deposit(4, token.address, ethers.utils.parseEther("1"))).to.reverted;
    });
  });
});
