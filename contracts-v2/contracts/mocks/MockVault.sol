// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "../interfaces/IRewardBondDepositor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MockVault {
  using SafeERC20 for IERC20;

  uint256 public balance;
  mapping(address => uint256) public balanceOf;
  address[] public rewardTokens;
  address depositor;

  constructor(address _depositor, address[] memory _rewardTokens) {
    depositor = _depositor;
    rewardTokens = _rewardTokens;
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      IERC20(_rewardTokens[i]).safeApprove(_depositor, uint256(-1));
    }
  }

  function addBalance(address _user, uint256 _amount) external {
    balance = balance + _amount;
    balanceOf[_user] = balanceOf[_user] + _amount;
  }

  function subBalance(address _user, uint256 _amount) external {
    balance = balance - _amount;
    balanceOf[_user] = balanceOf[_user] - _amount;
  }

  function notify(address _user, uint256[] memory _amounts) external {
    IRewardBondDepositor(depositor).notifyRewards(_user, _amounts);
  }

  function changeBalanceAndNotify(
    address _user,
    int256 _delta,
    uint256[] memory _amounts
  ) external {
    IRewardBondDepositor(depositor).notifyRewards(_user, _amounts);

    balance = uint256(int256(balance) + _delta);
    balanceOf[_user] = uint256(int256(balanceOf[_user]) + _delta);
  }

  function getRewardTokens() external view returns (address[] memory) {
    return rewardTokens;
  }
}
