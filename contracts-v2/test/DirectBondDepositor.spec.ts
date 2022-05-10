/* eslint-disable node/no-missing-import */
import { DirectBondDepositor, MockERC20, MockStaking, Treasury } from "../typechain";
import { MockContract } from "ethereum-waffle";
import { ethers } from "hardhat";
import { deployMockForName } from "./mock";
import "./utils";
import { Signer } from "ethers";
import { expect } from "chai";

describe("DirectBondDepositor.spec", async () => {
  let deployer: Signer;
  let dao: Signer;

  let ald: MockERC20;
  let token: MockERC20;
  let treasury: Treasury;
  let staking: MockStaking;
  let bond: DirectBondDepositor;
  let mockOracle: MockContract;

  beforeEach(async () => {
    [deployer, dao] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20", deployer);
    ald = await MockERC20.deploy("ALD", "ALD", 18);
    await ald.deployed();
    token = await MockERC20.deploy("token", "token", 18);
    await token.deployed();

    const Treasury = await ethers.getContractFactory("Treasury", deployer);
    treasury = await Treasury.deploy(ald.address, await dao.getAddress());
    await treasury.deployed();

    const DirectBondDepositor = await ethers.getContractFactory("DirectBondDepositor", deployer);
    bond = await DirectBondDepositor.deploy(ald.address, treasury.address);
    await bond.deployed();

    const MockStaking = await ethers.getContractFactory("MockStaking", deployer);
    staking = await MockStaking.deploy(ald.address);
    await staking.deployed();

    await bond.initialize(staking.address);

    mockOracle = await deployMockForName(deployer, "IPriceOracle");
    await treasury.updatePriceOracle(token.address, mockOracle.address);
    await treasury.updateDiscount(token.address, "1100000000000000000"); // 110%
    await treasury.updatePercentagePOL(token.address, "500000000000000000"); // 50%
    await treasury.updateReserveToken(token.address, true);
    await treasury.updateReserveDepositor(bond.address, true);
    await token.mint(await deployer.getAddress(), ethers.utils.parseEther("100"));
    await ald.mint(await deployer.getAddress(), ethers.utils.parseEther("100"));
  });

  context("#deposit", async () => {
    it("should revert, when token not approved", async () => {
      await expect(
        bond.deposit(token.address, ethers.utils.parseEther("1"), ethers.utils.parseEther("1"))
      ).to.revertedWith("DirectBondDepositor: not approved");
    });

    it("should revert, when bond amout not enough", async () => {
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await bond.updateBondAsset(token.address, true);
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);

      const expected = await bond.getBondALD(token.address, ethers.utils.parseEther("1"));
      expect(expected).to.closeToBnR("7895080878992244080", 1, 1000000);

      await token.approve(bond.address, ethers.utils.parseEther("1"));
      await expect(bond.deposit(token.address, ethers.utils.parseEther("1"), expected.add(1))).to.revertedWith(
        "DirectBondDepositor: bond not enough"
      );
    });

    it("should succeed when deposit normal asset", async () => {
      await mockOracle.mock.value.returns(ethers.utils.parseEther("10"));
      await bond.updateBondAsset(token.address, true);
      await treasury.updateReserves(ethers.utils.parseEther("10"), 0, 0);

      const expected = await bond.getBondALD(token.address, ethers.utils.parseEther("1"));
      expect(expected).to.closeToBnR("7895080878992244080", 1, 1000000);

      await token.approve(bond.address, ethers.utils.parseEther("1"));
      await bond.deposit(token.address, ethers.utils.parseEther("1"), expected);
      // about 100 * (pow(2, 0.1) - 1) * 1.1
      expect(await ald.balanceOf(staking.address)).to.eq(expected);
      expect(await treasury.totalReserveUnderlying()).to.eq(ethers.utils.parseEther("20"));
      // about 100 * (pow(2, 0.1) - 1) * 1.1 * 0.05 / 0.95
      expect(await ald.balanceOf(await dao.getAddress())).to.eq(expected.mul(5).div(95));
      expect(await treasury.polReserves(token.address)).to.eq(ethers.utils.parseEther("0.5"));
    });
  });
});
