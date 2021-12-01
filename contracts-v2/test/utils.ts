import { Assertion } from "chai";
import { BigNumber, BigNumberish } from "ethers";
import { ethers } from "hardhat";

export async function latest() {
  const block = await ethers.provider.getBlock("latest");
  return ethers.BigNumber.from(block.timestamp);
}

export async function latestBlockNumber() {
  const block = await ethers.provider.getBlock("latest");
  return ethers.BigNumber.from(block.number);
}

export async function advanceBlock(): Promise<void> {
  await ethers.provider.send("evm_mine", []);
}

export async function advanceBlockTo(block: number) {
  let latestBlock = (await latestBlockNumber()).toNumber();

  if (block <= latestBlock) {
    throw new Error("input block exceeds current block");
  }

  while (block > latestBlock) {
    await advanceBlock();
    latestBlock++;
  }
}

export async function advanceBlockAtTime(time: number): Promise<void> {
  await ethers.provider.send("evm_mine", [time]);
}

export async function setNextBlockTime(time: number): Promise<void> {
  await ethers.provider.send("evm_setNextBlockTimestamp", [time]);
}

export async function increaseBlockTime(duration: number): Promise<void> {
  if (duration < 0) throw Error(`Cannot increase time by a negative amount (${duration})`);
  await ethers.provider.send("evm_increaseTime", [duration]);
  await advanceBlock();
}

/**
 * Note that failed transactions are silently ignored when automining is disabled.
 */
export async function setAutomine(flag: boolean): Promise<void> {
  await ethers.provider.send("evm_setAutomine", [flag]);
}

Assertion.addMethod("closeToBn", function (expected: BigNumberish, delta: BigNumberish) {
  const obj = this._obj;
  this.assert(
    BigNumber.from(expected).sub(obj).abs().lte(delta),
    `expected ${obj} to be close to ${expected} +/- ${delta}`,
    `expected ${obj} not to be close to ${expected} +/- ${delta}`,
    expected,
    obj
  );
});

Assertion.addMethod("closeToBnR", function (expected: BigNumberish, errNum: number, errDen: number) {
  const obj = this._obj;
  const delta = BigNumber.from(expected).mul(errNum).div(errDen);
  this.assert(
    BigNumber.from(expected).sub(obj).abs().lte(delta),
    `expected ${obj} to be close to ${expected} +/- ${delta}`,
    `expected ${obj} not to be close to ${expected} +/- ${delta}`,
    expected,
    obj
  );
});

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  export namespace Chai {
    interface Assertion {
      closeToBn(expected: BigNumberish, delta: BigNumberish): Assertion;
      closeToBnR(expected: BigNumberish, errNum: number, errDen: number): Assertion;
    }
  }
}
