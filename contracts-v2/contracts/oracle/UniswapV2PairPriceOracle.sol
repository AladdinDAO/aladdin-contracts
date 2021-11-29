// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract UniswapV2PairPriceOracle is Ownable, IPriceOracle {
  using SafeMath for uint256;

  // The address of Chainlink Oracle
  address public immutable chainlink;

  // The address ald token.
  address public immutable ald;

  /// @param _chainlink The address of chainlink oracle.
  /// @param _ald The address of ALD token.
  constructor(address _chainlink, address _ald) {
    require(_chainlink != address(0), "UniswapV2PairPriceOracle: zero address");
    require(_ald != address(0), "UniswapV2PairPriceOracle: zero address");

    chainlink = _chainlink;
    ald = _ald;
  }

  /// @dev Return the usd price of UniswapV2 pair. mutilpled by 1e18
  /// @notice We only consider the price without ALD.
  /// @param _pair The address of UniswapV2 pair
  function price(address _pair) public view override returns (uint256) {
    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();
    address _ald = ald;

    require(_token0 == _ald || _token1 == _ald, "UniswapV2PairPriceOracle: not supported");

    (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(_pair).getReserves();
    uint256 _totalSupply = IUniswapV2Pair(_pair).totalSupply();

    if (_token0 == _ald) {
      uint256 _amount = uint256(1e18).mul(_reserve1).div(_totalSupply);
      return IPriceOracle(chainlink).value(_token1, _amount);
    } else {
      uint256 _amount = uint256(1e18).mul(_reserve0).div(_totalSupply);
      return IPriceOracle(chainlink).value(_token0, _amount);
    }
  }

  /// @dev Return the usd value of UniswapV2 pair. mutilpled by 1e18
  /// @notice We only consider the value without ALD.
  /// @param _pair The address of UniswapV2 pair.
  /// @param _amount The amount of asset/
  function value(address _pair, uint256 _amount) external view override returns (uint256) {
    uint256 _price = price(_pair);
    return _price.mul(_amount).div(10**IERC20Metadata(_pair).decimals());
  }
}
