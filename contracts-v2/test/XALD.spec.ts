/* eslint-disable node/no-missing-import */
import { expect } from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { ethers } from "hardhat";
import { XALD } from "../typechain";

describe("XALD.spec", async () => {
  let deployer: Signer;
  let staking: Signer;
  let alice: Signer;
  let bob: Signer;

  let xald: XALD;

  beforeEach(async () => {
    [deployer, staking, alice, bob] = await ethers.getSigners();

    const XALD = await ethers.getContractFactory("XALD", deployer);
    xald = await XALD.deploy();

    expect(await xald.staking()).to.eq(constants.AddressZero);
    await xald.initialize(await staking.getAddress());
    expect(await xald.staking()).to.eq(await staking.getAddress());
  });

  context("#initialize", async () => {
    it("should revert, when call initialize again", async () => {
      await expect(xald.initialize(constants.AddressZero)).to.revertedWith("XALD: only initializer");
    });
  });

  context("#stake, #rebase and #unstake", async () => {
    it("should revert, when call is not staking", async () => {
      await expect(xald.stake(await deployer.getAddress(), ethers.utils.parseEther("1"))).to.revertedWith(
        "XALD: only staking contract"
      );
      await expect(xald.rebase(0, ethers.utils.parseEther("1"))).to.revertedWith("XALD: only staking contract");
    });

    it("should succeed", async () => {
      // stake 100 for alice
      await expect(xald.connect(staking).stake(await alice.getAddress(), ethers.utils.parseEther("100")))
        .to.emit(xald, "MintShare")
        .withArgs(await alice.getAddress(), ethers.utils.parseEther("100"));
      expect(await xald.balanceOf(await alice.getAddress())).to.eq(ethers.utils.parseEther("100"));
      expect(await xald.sharesOf(await alice.getAddress())).to.eq(ethers.utils.parseEther("100"));
      expect(await xald.totalSupply()).to.eq(ethers.utils.parseEther("100"));
      expect(await xald.totalShares()).to.eq(ethers.utils.parseEther("100"));

      // add 10 ald as reward
      await xald.connect(staking).rebase(0, ethers.utils.parseEther("10"));
      expect(await xald.totalSupply()).to.eq(ethers.utils.parseEther("110"));
      expect(await xald.totalShares()).to.eq(ethers.utils.parseEther("100"));

      // stake 100 for bob
      await expect(xald.connect(staking).stake(await bob.getAddress(), ethers.utils.parseEther("100")))
        .to.emit(xald, "MintShare")
        .withArgs(await bob.getAddress(), BigNumber.from("90909090909090909090"));
      expect(await xald.balanceOf(await bob.getAddress())).to.eq(BigNumber.from("99999999999999999999"));
      expect(await xald.sharesOf(await bob.getAddress())).to.eq(BigNumber.from("90909090909090909090"));
      expect(await xald.totalSupply()).to.eq(ethers.utils.parseEther("210"));
      expect(await xald.totalShares()).to.eq(BigNumber.from("190909090909090909090"));

      // add 10 ald as reward
      await xald.connect(staking).rebase(0, ethers.utils.parseEther("10"));
      expect(await xald.totalSupply()).to.eq(ethers.utils.parseEther("220"));
      expect(await xald.totalShares()).to.eq(BigNumber.from("190909090909090909090"));
      expect(await xald.balanceOf(await alice.getAddress())).to.eq(BigNumber.from("115238095238095238095"));
      expect(await xald.balanceOf(await bob.getAddress())).to.eq(BigNumber.from("104761904761904761904"));

      // alice transfer 100 ald to deploer
      await xald.connect(alice).transfer(await deployer.getAddress(), ethers.utils.parseEther("100"));
      expect(await xald.balanceOf(await deployer.getAddress())).to.eq(BigNumber.from("99999999999999999999"));
      expect(await xald.sharesOf(await deployer.getAddress())).to.eq(BigNumber.from("86776859504132231404"));
      expect(await xald.balanceOf(await alice.getAddress())).to.eq(BigNumber.from("15238095238095238096"));
      expect(await xald.sharesOf(await alice.getAddress())).to.eq(BigNumber.from("13223140495867768596"));
    });
  });
});
