// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITreasury {
  enum ReserveType {
    // used by reserve manager, will not used to bond ALD.
    NULL,
    // used by main asset bond
    UNDERLYING,
    // used by vault reward bond
    VAULT_REWARD,
    // used by liquidity token bond
    LIQUIDITY_TOKEN
  }

  /// @dev return the usd value given token and amount.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function valueOf(address _token, uint256 _amount) external view returns (uint256);

  /// @dev return the amount of bond ALD given token and usd value.
  /// @param _token The address of token.
  /// @param _value The usd of token.
  function bondOf(address _token, uint256 _value) external view returns (uint256);

  /// @dev deposit token to bond ALD.
  /// @param _type The type of deposited token.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function deposit(
    ReserveType _type,
    address _token,
    uint256 _amount
  ) external returns (uint256);

  /// @dev withdraw token from POL.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function withdraw(address _token, uint256 _amount) external;

  /// @dev manage token to earn passive yield.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function manage(address _token, uint256 _amount) external;

  /// @dev mint ALD reward.
  /// @param _recipient The address of to receive ALD token.
  /// @param _amount The amount of token.
  function mintRewards(address _recipient, uint256 _amount) external;
}
