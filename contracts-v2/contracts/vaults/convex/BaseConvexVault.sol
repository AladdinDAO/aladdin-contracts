// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../MultipleRewardsVaultBase.sol";

interface IBooster {
  struct PoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
  }

  function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _stake
  ) external returns (bool);

  function depositAll(uint256 _pid, bool _stake) external returns (bool);

  function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

  function withdrawAll(uint256 _pid) external returns (bool);
}

interface IBaseRewardPool {
  function balanceOf(address account) external view returns (uint256);

  function getReward() external returns (bool);

  function getReward(address _account, bool _claimExtras) external returns (bool);

  function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

  function earned(address _account) external view returns (uint256);
}

abstract contract BaseConvexVault is MultipleRewardsVaultBase {
  using SafeERC20 for IERC20;

  IBooster public booster;
  IBaseRewardPool public cvxRewardPool;

  uint256 public pid;

  constructor(
    address _baseToken,
    address _depositor,
    address _governor,
    address _booster,
    uint256 _pid
  ) MultipleRewardsVaultBase(_baseToken, _depositor, _governor) {
    IBooster.PoolInfo memory info = IBooster(_booster).poolInfo(_pid);
    require(info.lptoken == _baseToken, "invalid pid or token");

    booster = IBooster(_booster);
    cvxRewardPool = IBaseRewardPool(info.crvRewards);
    pid = _pid;
  }

  // Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal override {
    IERC20 _baseToken = IERC20(baseToken);
    uint256 amount = _baseToken.balanceOf(address(this));
    if (amount > 0) {
      IBooster _booster = booster;
      _baseToken.safeApprove(address(_booster), amount);
      _booster.deposit(pid, amount, true);
    }
  }

  // Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal override {
    cvxRewardPool.withdrawAndUnwrap(_amount, false);
  }

  // Harvest rewards from strategy into vault
  function _harvest() internal override {
    cvxRewardPool.getReward();
  }

  // Balance of deposit token in underlying strategy
  function _strategyBalance() internal view override returns (uint256) {
    // The cvxStakeToken is 1:1 with lpToken
    return cvxRewardPool.balanceOf(address(this));
  }
}
