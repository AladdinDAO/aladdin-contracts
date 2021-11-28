// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IRewardBondDepositor.sol";
import "./VaultBase.sol";

abstract contract MultipleRewardsVaultBase is VaultBase {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address[] private rewardTokens;

  uint256 public lastUpdateBlock;
  mapping(uint256 => uint256) public rewardsPerShareStored;
  mapping(address => mapping(uint256 => uint256)) public userRewardPerSharePaid;
  mapping(address => mapping(uint256 => uint256)) public rewards;

  constructor(
    address _token,
    address _depositor,
    address _governor,
    address[] memory _rewardTokens
  ) VaultBase(_token, _depositor, _governor) {
    rewardTokens = _rewardTokens;
  }

  function getRewardTokens() external view override returns (address[] memory) {
    return rewardTokens;
  }

  function earned(address account, uint256 index) public view returns (uint256) {
    uint256 _balance = balanceOf[account];
    return
      _balance.mul(rewardsPerShareStored[index].sub(userRewardPerSharePaid[account][index])).div(PRECISION).add(
        rewards[account][index]
      );
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

    uint256 length = rewardTokens.length;
    for (uint256 i = 0; i < length; i++) {
      uint256 reward = rewards[msg.sender][i];
      if (reward > 0) {
        rewards[msg.sender][i] = 0;
        IERC20(rewardTokens[i]).safeTransfer(msg.sender, reward);
      }
    }

    // TODO: event
  }

  function exit() external override {
    withdraw(balanceOf[msg.sender]);
    claim();
  }

  function harvest() public override {
    uint256 length = rewardTokens.length;
    uint256[] memory harvested = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      harvested[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
    }
    // Harvest rewards from strategy
    _harvest();

    for (uint256 i = 0; i < length; i++) {
      harvested[i] = IERC20(rewardTokens[i]).balanceOf(address(this)).sub(harvested[i]);
    }

    {
      uint256[] memory _amounts = new uint256[](length);
      for (uint256 i = 0; i < length; i++) {
        _amounts[i] = harvested[i].mul(bondPercentage).div(PRECISION);
        harvested[i] = harvested[i].sub(_amounts[i]);
      }
      IRewardBondDepositor(depositor).notifyRewards(msg.sender, _amounts);
    }

    // distribute new rewards to current shares evenly
    for (uint256 i = 0; i < length; i++) {
      rewardsPerShareStored[i] = rewardsPerShareStored[i].add(harvested[i].mul(1e18).div(balance));
    }

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

    uint256 length = rewardTokens.length;
    for (uint256 i = 0; i < length; i++) {
      rewards[account][i] = earned(account, i);
      userRewardPerSharePaid[account][i] = rewardsPerShareStored[i];
    }
  }
}
