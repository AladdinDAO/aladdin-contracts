/* eslint-disable node/no-missing-import */
import { expect } from "chai";
import { BigNumber, Signer, Contract } from "ethers";
import { ethers } from "hardhat";
import { MockContract } from "ethereum-waffle";
import { deployMockForName } from "./mock";

describe("ChainlinkPriceOracle.spec", async () => {
  let deployer: Signer;
  let alice: Signer;

  let chainLinkOracle: Contract;
  let chainLinkOracleAsAlice: Contract;
  let token0: Contract;
  let token1: Contract;
  let mockAggregator: MockContract;

  beforeEach(async () => {
    [deployer, alice] = await ethers.getSigners();

    const ERC20 = await ethers.getContractFactory("MockERC20", deployer);
    token0 = await ERC20.deploy("token0", "token0", 18);
    await token0.deployed();
    token1 = await ERC20.deploy("token1", "token1", 8);
    await token1.deployed();

    mockAggregator = await deployMockForName(deployer, "AggregatorV3Interface");

    const ChainlinkPriceOracle = await ethers.getContractFactory("ChainlinkPriceOracle", deployer);
    chainLinkOracle = await ChainlinkPriceOracle.deploy();
    await chainLinkOracle.deployed();
    chainLinkOracleAsAlice = chainLinkOracle.connect(alice);
  });

  context("#updateFeed", async () => {
    context("when the caller is not the owner", async () => {
      it("should revert", async () => {
        await expect(chainLinkOracleAsAlice.updateFeed(token0.address, mockAggregator.address)).to.revertedWith(
          "Ownable: caller is not the owner"
        );
      });
    });

    context("when the caller is the owner", async () => {
      it("should succeed", async () => {
        await expect(chainLinkOracle.updateFeed(token0.address, mockAggregator.address))
          .to.emit(chainLinkOracle, "UpdateFeed")
          .withArgs(token0.address, mockAggregator.address);

        expect(await chainLinkOracle.feeds(token0.address)).to.be.eq(mockAggregator.address);
      });
    });
  });

  context("#price", async () => {
    it("should revert, when no source", async () => {
      await expect(chainLinkOracle.price(token0.address)).to.revertedWith("ChainlinkPriceOracle: not supported");
    });

    it("should succeed", async () => {
      await chainLinkOracle.updateFeed(token0.address, mockAggregator.address);

      // decimal is 8
      await mockAggregator.mock.decimals.returns(8);
      // result should be (priceT0 * 1e18) / (10**decimals) = (36500000000 * 1e18) / (10**8) = 365000000000000000000
      await mockAggregator.mock.latestRoundData.returns(0, BigNumber.from("36500000000"), 0, 0, 0);
      expect(await chainLinkOracle.price(token0.address)).to.be.eq(BigNumber.from("365000000000000000000"));

      // result should be (priceT0 * 1e18) / (10**decimals) = (273972 * 1e18) / (10 ** 8) = 2739720000000000
      await mockAggregator.mock.latestRoundData.returns(0, BigNumber.from("273972"), 0, 0, 0);
      expect(await chainLinkOracle.price(token0.address)).to.be.eq(BigNumber.from("2739720000000000"));

      // result should be (priceT2 * 1e18) / (10**decimals) = (100000000 * 1e18) / (10**8) = 1000000000000000000
      await mockAggregator.mock.latestRoundData.returns(0, BigNumber.from("100000000"), 0, 0, 0);
      expect(await chainLinkOracle.price(token0.address)).to.be.eq(BigNumber.from("1000000000000000000"));

      // decimal is 19
      await mockAggregator.mock.decimals.returns(19);
      // result should be (priceT3 * 1e18) / (10**decimals) = (10000000000000000000 * 1e18) / (10**19) = 1000000000000000000
      await mockAggregator.mock.latestRoundData.returns(0, BigNumber.from("10000000000000000000"), 0, 0, 0);
      expect(await chainLinkOracle.price(token0.address)).to.be.eq(BigNumber.from("1000000000000000000"));
    });
  });

  context("#value", async () => {
    it("should revert, when no source", async () => {
      await expect(chainLinkOracle.value(token0.address, ethers.utils.parseEther("10"))).to.revertedWith(
        "ChainlinkPriceOracle: not supported"
      );
    });

    it("should succeed", async () => {
      await chainLinkOracle.updateFeed(token0.address, mockAggregator.address);
      await chainLinkOracle.updateFeed(token1.address, mockAggregator.address);

      // decimal is 8
      await mockAggregator.mock.decimals.returns(8);
      // result should be (priceT0 * 1e18) / (10**decimals) = (36500000000 * 1e18) / (10**8) = 365000000000000000000
      await mockAggregator.mock.latestRoundData.returns(0, BigNumber.from("36500000000"), 0, 0, 0);
      expect(await chainLinkOracle.value(token0.address, ethers.utils.parseEther("10"))).to.be.eq(
        BigNumber.from("3650000000000000000000")
      );
      expect(await chainLinkOracle.value(token1.address, ethers.utils.parseUnits("10", 8))).to.be.eq(
        BigNumber.from("3650000000000000000000")
      );

      // result should be (priceT0 * 1e18) / (10**decimals) = (273972 * 1e18) / (10 ** 8) = 2739720000000000
      await mockAggregator.mock.latestRoundData.returns(0, BigNumber.from("273972"), 0, 0, 0);
      expect(await chainLinkOracle.value(token0.address, ethers.utils.parseEther("10"))).to.be.eq(
        BigNumber.from("27397200000000000")
      );
      expect(await chainLinkOracle.value(token1.address, ethers.utils.parseUnits("10", 8))).to.be.eq(
        BigNumber.from("27397200000000000")
      );

      // result should be (priceT2 * 1e18) / (10**decimals) = (100000000 * 1e18) / (10**8) = 1000000000000000000
      await mockAggregator.mock.latestRoundData.returns(0, BigNumber.from("100000000"), 0, 0, 0);
      expect(await chainLinkOracle.value(token0.address, ethers.utils.parseEther("10"))).to.be.eq(
        BigNumber.from("10000000000000000000")
      );
      expect(await chainLinkOracle.value(token1.address, ethers.utils.parseUnits("10", 8))).to.be.eq(
        BigNumber.from("10000000000000000000")
      );

      // decimal is 19
      await mockAggregator.mock.decimals.returns(19);
      // result should be (priceT3 * 1e18) / (10**decimals) = (10000000000000000000 * 1e18) / (10**19) = 1000000000000000000
      await mockAggregator.mock.latestRoundData.returns(0, BigNumber.from("10000000000000000000"), 0, 0, 0);
      expect(await chainLinkOracle.value(token0.address, ethers.utils.parseEther("10"))).to.be.eq(
        BigNumber.from("10000000000000000000")
      );
      expect(await chainLinkOracle.value(token1.address, ethers.utils.parseUnits("10", 8))).to.be.eq(
        BigNumber.from("10000000000000000000")
      );
    });
  });
});
