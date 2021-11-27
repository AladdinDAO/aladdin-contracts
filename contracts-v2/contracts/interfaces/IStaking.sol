// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IStaking {

  function stake(uint256 _amount) external;

  function stakeFor(address _recipient, uint256 _amount) external;

  function unstake(address _recipient, uint256 _amount) external;

  function unstakeAll(address _recipient) external;

  function bondFor(address _recipient, uint256 _amount) external;

  function rewardBond(uint256 _epoch, address[] memory _tokens, uint256[] memory _amounts) external;

  function redeem(address _recipient, bool _withdraw) external;
}