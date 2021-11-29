/* eslint-disable node/no-missing-import */
import { expect } from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { ethers } from "hardhat";
import { WrappedXALD, XALD } from "../typechain";

describe("XALD.spec", async () => {
  let deployer: Signer;
  let staking: Signer;
  let alice: Signer;
  let bob: Signer;

  let xald: XALD;
  let wxald: WrappedXALD;

  beforeEach(async () => {
    [deployer, staking, alice, bob] = await ethers.getSigners();

    const XALD = await ethers.getContractFactory("XALD", deployer);
    xald = await XALD.deploy();

    const WrappedXALD = await ethers.getContractFactory("WrappedXALD", deployer);
    wxald = await WrappedXALD.deploy(xald.address);

    expect(await xald.staking()).to.eq(constants.AddressZero);
    await xald.initialize(await staking.getAddress());
    expect(await xald.staking()).to.eq(await staking.getAddress());

    // stake 100 for alice
    await xald.connect(staking).stake(await alice.getAddress(), ethers.utils.parseEther("100"));
    // add 10 ald as reward
    await xald.connect(staking).rebase(0, ethers.utils.parseEther("10"));
    // stake 100 for bob
    xald.connect(staking).stake(await bob.getAddress(), ethers.utils.parseEther("100"));
  });

  context("#wrap, #rebase and #unwrap", async () => {
    it("should succeed", async () => {
      // bob wrap 50 xALD
      await xald.connect(bob).approve(wxald.address, ethers.utils.parseEther("50"));
      await wxald.connect(bob).wrap(ethers.utils.parseEther("50"));
      expect(await wxald.balanceOf(await bob.getAddress())).to.eq(BigNumber.from("45454545454545454545"));

      // bob transfer half wxALD to deployer
      await wxald.connect(bob).transfer(await deployer.getAddress(), "22727272727272727272");

      // add 10 ald as reward
      await xald.connect(staking).rebase(0, ethers.utils.parseEther("10"));

      // deployer unwrap all wxALD
      await wxald.connect(deployer).unwrap("22727272727272727272");
      expect(await xald.balanceOf(await deployer.getAddress())).to.eq(BigNumber.from("26190476190476190474"));
      expect(await xald.balanceOf(wxald.address)).to.eq(BigNumber.from("26190476190476190477"));
    });
  });
});
