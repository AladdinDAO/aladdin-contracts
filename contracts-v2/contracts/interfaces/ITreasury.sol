// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITreasury {
  enum ReserveType {
    // used by reserve manager
    NULL,
    // used by main asset bond
    UNDERLYING,
    // used by vault reward bond
    VAULT_REWARD,
    // used by liquidity token bond
    LIQUIDITY_TOKEN
  }

  function valueOf(address _token, uint256 _amount) external view returns (uint256);

  function bondOf(address _token, uint256 _value) external view returns (uint256);

  function deposit(
    ReserveType _type,
    address _token,
    uint256 _amount
  ) external returns (uint256);

  function withdraw(address _token, uint256 _amount) external;

  function manage(address _token, uint256 _amount) external;

  function mintRewards(address _recipient, uint256 _amount) external;
}
