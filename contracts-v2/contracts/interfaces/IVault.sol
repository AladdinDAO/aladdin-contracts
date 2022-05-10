// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IVault {
  function getRewardTokens() external view returns (address[] memory);

  function balance() external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function claim() external;

  function exit() external;

  function harvest() external;
}
