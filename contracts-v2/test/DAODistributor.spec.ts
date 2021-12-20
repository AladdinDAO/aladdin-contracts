/* eslint-disable node/no-missing-import */
import { DAODistributor, MockERC20 } from "../typechain";
import { ethers } from "hardhat";
import "./utils";
import { constants, Signer } from "ethers";
import { expect } from "chai";

describe("DAODistributor.spec", async () => {
  let deployer: Signer;
  let alice: Signer;
  let bob: Signer;
  let keeper: Signer;

  let ald: MockERC20;
  let token: MockERC20;
  let dao: DAODistributor;

  beforeEach(async () => {
    [deployer, keeper, alice, bob] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20", deployer);
    ald = await MockERC20.deploy("ALD", "ALD", 18);
    await ald.deployed();
    token = await MockERC20.deploy("token", "token", 18);
    await token.deployed();

    const DAODistributor = await ethers.getContractFactory("DAODistributor", deployer);
    dao = await DAODistributor.deploy(ald.address, await keeper.getAddress());
    await dao.deployed();
  });

  context("#updateRecipients", async () => {
    it("should revert, when non owner is operate", async () => {
      await expect(dao.connect(alice).updateRecipients([], [])).to.revertedWith("Ownable: caller is not the owner");
    });

    it("should revert, when length mismatch", async () => {
      await expect(dao.updateRecipients([], [0])).to.revertedWith("DAODistributor: length mismatch");
    });

    it("should revert, when duplicate recipent", async () => {
      await expect(dao.updateRecipients([constants.AddressZero, constants.AddressZero], [0, 0])).to.revertedWith(
        "DAODistributor: duplicate recipient"
      );
    });

    it("should revert, when sum is not 100%", async () => {
      await expect(dao.updateRecipients([await alice.getAddress(), await bob.getAddress()], [1, 2])).to.revertedWith(
        "DAODistributor: sum should be 100%"
      );
    });

    it("should succeed", async () => {
      expect(await dao.length()).to.eq(constants.Zero);
      expect(await dao.recipients(0)).to.eq(constants.AddressZero);
      expect(await dao.recipients(1)).to.eq(constants.AddressZero);
      expect(await dao.percentage(0)).to.eq(constants.Zero);
      expect(await dao.percentage(1)).to.eq(constants.Zero);
      await dao.updateRecipients(
        [await alice.getAddress(), await bob.getAddress()],
        [ethers.utils.parseEther("0.1"), ethers.utils.parseEther("0.9")]
      );
      expect(await dao.length()).to.eq(constants.Two);
      expect(await dao.recipients(0)).to.eq(await alice.getAddress());
      expect(await dao.recipients(1)).to.eq(await bob.getAddress());
      expect(await dao.percentage(0)).to.eq(ethers.utils.parseEther("0.1"));
      expect(await dao.percentage(1)).to.eq(ethers.utils.parseEther("0.9"));
    });
  });

  context("#distribute", async () => {
    it("should revert, when non keeper call distribute", async () => {
      await expect(dao.distribute()).to.revertedWith("DAODistributor: only keeper");
    });

    it("should revert, when non owner update keeper", async () => {
      await expect(dao.connect(alice).updateKeeper(await alice.getAddress())).to.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("should succed, when update keeper", async () => {
      await expect(dao.connect(alice).distribute()).to.revertedWith("DAODistributor: only keeper");
      expect(await dao.keeper()).to.eq(await keeper.getAddress());
      await dao.updateKeeper(await alice.getAddress());
      expect(await dao.keeper()).to.eq(await alice.getAddress());
      await dao.connect(alice).distribute();
    });

    it("should distribute correctly", async () => {
      await dao.updateRecipients(
        [await alice.getAddress(), await bob.getAddress()],
        [ethers.utils.parseEther("0.1"), ethers.utils.parseEther("0.9")]
      );
      await ald.mint(dao.address, ethers.utils.parseEther("100"));
      await dao.connect(keeper).distribute();
      expect(await ald.balanceOf(await alice.getAddress())).to.eq(ethers.utils.parseEther("10"));
      expect(await ald.balanceOf(await bob.getAddress())).to.eq(ethers.utils.parseEther("90"));
    });
  });
});
