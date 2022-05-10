// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IPriceOracle {
  /// @dev Return the usd price of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  function price(address _asset) external view returns (uint256);

  /// @dev Return the usd value of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  /// @param _amount The amount of asset
  function value(address _asset, uint256 _amount) external view returns (uint256);
}
