// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IPriceOracle {
  function price(address _asset) external view returns (uint256);

  function value(address _asset, uint256 _amount) external view returns (uint256);
}