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

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event Harvest(address indexed keeper, uint256 bondAmount, uint256 rewardAmount);

  // The address of reward token.
  address private rewardToken;

  // The last harvest block number.
  uint256 public lastUpdateBlock;
  // The reward per share.
  uint256 public rewardsPerShareStored;
  // Mapping from user address to reward per share paid.
  mapping(address => uint256) public userRewardPerSharePaid;
  // Mapping from user address to reward amount.
  mapping(address => uint256) public rewards;

  /// @param _baseToken The address of staked token.
  /// @param _depositor The address of RewardBondDepositor.
  /// @param _governor The address of governor.
  /// @param _rewardToken The address of reward token.
  constructor(
    address _baseToken,
    address _depositor,
    address _governor,
    address _rewardToken
  ) VaultBase(_baseToken, _depositor, _governor) {
    rewardToken = _rewardToken;

    IERC20(_rewardToken).safeApprove(_depositor, uint256(-1));
  }

  /// @dev return the reward tokens in current vault.
  function getRewardTokens() external view override returns (address[] memory) {
    address[] memory result = new address[](1);
    result[0] = rewardToken;
    return result;
  }

  /// @dev return the reward token earned in current vault.
  /// @param _account The address of account.
  function earned(address _account) public view returns (uint256) {
    uint256 _balance = balanceOf[_account];
    return
      _balance.mul(rewardsPerShareStored.sub(userRewardPerSharePaid[_account])).div(PRECISION).add(rewards[_account]);
  }

  /// @dev Amount of deposit token per vault share
  function getPricePerFullShare() public view returns (uint256) {
    if (balance == 0) return 0;
    return _strategyBalance().mul(PRECISION).div(balance);
  }

  /// @dev Deposit baseToken to vault.
  /// @param _amount The amount of token to deposit.
  function deposit(uint256 _amount) external override nonReentrant {
    _updateReward(msg.sender);

    address _token = baseToken; // gas saving
    uint256 _pool = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    _amount = IERC20(_token).balanceOf(address(this)).sub(_pool);

    uint256 _share;
    if (balance == 0) {
      _share = _amount;
    } else {
      _share = _amount.mul(balance).div(_strategyBalance());
    }

    balance = balance.add(_share);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_share);

    _deposit();

    emit Deposit(msg.sender, _amount);
  }

  /// @dev Withdraw baseToken from vault.
  /// @param _share The share of vault to withdraw.
  function withdraw(uint256 _share) public override nonReentrant {
    require(_share <= balanceOf[msg.sender], "Vault: not enough share");
    _updateReward(msg.sender);

    uint256 _amount = _share.mul(_strategyBalance()).div(balance);

    // sub will not overflow here.
    balanceOf[msg.sender] = balanceOf[msg.sender] - _share;
    balance = balance - _share;

    address _token = baseToken; // gas saving
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

    emit Withdraw(msg.sender, _amount);
  }

  /// @dev Claim pending reward from vault.
  function claim() public override {
    _updateReward(msg.sender);

    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      IERC20(rewardToken).safeTransfer(msg.sender, reward);
    }

    emit Claim(msg.sender, reward);
  }

  /// @dev Withdraw and claim pending reward from vault.
  function exit() external override {
    withdraw(balanceOf[msg.sender]);
    claim();
  }

  /// @dev harvest pending reward from strategy.
  function harvest() public override {
    if (lastUpdateBlock == block.number) {
      return;
    }
    lastUpdateBlock = block.number;
    if (balance == 0) {
      IRewardBondDepositor(depositor).notifyRewards(msg.sender, new uint256[](1));
      return;
    }

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

    uint256 rewardAmount = harvested.sub(bondAmount);
    // distribute new rewards to current shares evenly
    rewardsPerShareStored = rewardsPerShareStored.add(rewardAmount.mul(1e18).div(balance));

    emit Harvest(msg.sender, bondAmount, rewardAmount);
  }

  /********************************** STRATEGY FUNCTIONS **********************************/

  /// @dev Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal virtual;

  /// @dev Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal virtual;

  /// @dev Harvest rewards from strategy into vault
  function _harvest() internal virtual;

  /// @dev Return the amount of baseToken in strategy.
  function _strategyBalance() internal view virtual returns (uint256);

  /********************************** INTERNAL FUNCTIONS **********************************/

  /// @dev Update pending reward for user.
  /// @param _account The address of account.
  function _updateReward(address _account) internal {
    harvest();

    rewards[_account] = earned(_account);
    userRewardPerSharePaid[_account] = rewardsPerShareStored;
  }
}
