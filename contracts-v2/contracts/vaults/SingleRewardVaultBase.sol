// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IRewardBondDepositor.sol";
import "./VaultBase.sol";

abstract contract SingleRewardVaultBase is VaultBase {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address private rewardToken;

  uint256 public lastUpdateBlock;
  uint256 public rewardsPerShareStored;
  mapping(address => uint256) public userRewardPerSharePaid;
  mapping(address => uint256) public rewards;

  constructor(
    address _token,
    address _depositor,
    address _governor,
    address _rewardToken
  ) VaultBase(_token, _depositor, _governor) {
    rewardToken = _rewardToken;
  }

  function getRewardTokens() external view override returns (address[] memory) {
    address[] memory result = new address[](1);
    result[0] = rewardToken;
    return result;
  }

  function earned(address account) public view returns (uint256) {
    uint256 _balance = balanceOf[account];
    return
      _balance.mul(rewardsPerShareStored.sub(userRewardPerSharePaid[account])).div(PRECISION).add(rewards[account]);
  }

  function deposit(uint256 _amount) external override nonReentrant {
    _updateReward(msg.sender);

    address _token = token; // gas saving
    uint256 _pool = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    _amount = IERC20(_token).balanceOf(address(this)).sub(_pool);

    balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);
    _deposit();

    // TODO: event
  }

  function withdraw(uint256 _amount) public override nonReentrant {
    _updateReward(msg.sender);

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);

    address _token = token; // gas saving
    uint256 _pool = IERC20(_token).balanceOf(address(this));
    if (_pool < _amount) {
      uint256 _withdrawAmount = _amount - _pool;
      // Withdraw from strategy
      _withdraw(_withdrawAmount);
      uint256 _poolAfter = IERC20(_token).balanceOf(address(this));
      uint256 _diff = _poolAfter.sub(_pool);
      if (_diff < _withdrawAmount) {
        _amount = _pool.add(_diff);
      }
    }

    IERC20(_token).safeTransfer(msg.sender, _amount);

    // TODO: event
  }

  function claim() public override {
    _updateReward(msg.sender);

    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      IERC20(rewardToken).safeTransfer(msg.sender, reward);
    }

    // TODO: event
  }

  function exit() external override {
    withdraw(balanceOf[msg.sender]);
    claim();
  }

  function harvest() public override {
    uint256 harvested = IERC20(rewardToken).balanceOf(address(this));
    // Harvest rewards from strategy
    _harvest();
    harvested = IERC20(rewardToken).balanceOf(address(this)).sub(harvested);

    uint256 bondAmount = harvested.mul(bondPercentage).div(PRECISION);
    {
      uint256[] memory _amounts = new uint256[](1);
      _amounts[0] = bondAmount;
      IRewardBondDepositor(depositor).notifyRewards(msg.sender, _amounts);
    }

    uint256 newRewardAmount = harvested.sub(bondAmount);
    // distribute new rewards to current shares evenly
    rewardsPerShareStored = rewardsPerShareStored.add(newRewardAmount.mul(1e18).div(balance));

    // TODO: event
  }

  /********************************** STRATEGY FUNCTIONS **********************************/

  // Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal virtual;

  // Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal virtual;

  // Harvest rewards from strategy into vault
  function _harvest() internal virtual;

  /********************************** INTERNAL FUNCTIONS **********************************/

  function _updateReward(address account) internal {
    if (lastUpdateBlock == block.number) {
      return;
    }
    lastUpdateBlock = block.number;

    harvest();

    rewards[account] = earned(account);
    userRewardPerSharePaid[account] = rewardsPerShareStored;
  }
}
