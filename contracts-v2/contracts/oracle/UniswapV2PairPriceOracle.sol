// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IUniswapV2Pair.sol";

interface IUniswapTWAPOracle {
  function pair() external view returns (address);

  function quote(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 points
  ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo);
}

contract UniswapV2PairPriceOracle is Ownable, IPriceOracle {
  using SafeMath for uint256;

  event UpdateTWAP(address indexed asset, address pair);
  event UpdateMaxPriceDiff(uint256 maxPriceDiff);

  // The address of Chainlink Oracle
  address public immutable chainlink;

  // The address ald token.
  address public immutable ald;

  // Mapping from pair address to twap address.
  mapping(address => address) public twaps;

  // The max price diff between spot price and twap price.
  uint256 public maxPriceDiff;

  /// @param _chainlink The address of chainlink oracle.
  /// @param _ald The address of ALD token.
  constructor(address _chainlink, address _ald) {
    require(_chainlink != address(0), "UniswapV2PairPriceOracle: zero address");
    require(_ald != address(0), "UniswapV2PairPriceOracle: zero address");

    chainlink = _chainlink;
    ald = _ald;
  }

  /// @dev Return the usd price of UniswapV2 pair. mutilpled by 1e18
  /// @notice We will also consider the price with ALD.
  /// @param _pair The address of UniswapV2 pair
  function price(address _pair) public view override returns (uint256) {
    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();
    address _ald = ald;

    require(_token0 == _ald || _token1 == _ald, "UniswapV2PairPriceOracle: not supported");

    (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(_pair).getReserves();
    uint256 _totalSupply = IUniswapV2Pair(_pair).totalSupply();

    if (_token0 == _ald) {
      _validate(_pair, _ald, _token1, _reserve0, _reserve1);
      uint256 _amount = uint256(1e18).mul(_reserve1).div(_totalSupply);
      return IPriceOracle(chainlink).value(_token1, _amount) * 2;
    } else {
      _validate(_pair, _ald, _token0, _reserve1, _reserve0);
      uint256 _amount = uint256(1e18).mul(_reserve0).div(_totalSupply);
      return IPriceOracle(chainlink).value(_token0, _amount) * 2;
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

  /// @dev Update the TWAP Oracle address for UniswapV2 pair
  /// @param _pair The address of UniswapV2 pair
  /// @param _twap The address of twap oracle.
  function updateTWAP(address _pair, address _twap) external onlyOwner {
    require(IUniswapTWAPOracle(_twap).pair() == _pair, "UniswapV2PairPriceOracle: invalid twap");

    twaps[_pair] = _twap;

    emit UpdateTWAP(_pair, _twap);
  }

  /// @dev Update the max price diff between spot price and twap price.
  /// @param _maxPriceDiff The max price diff.
  function updatePriceDiff(uint256 _maxPriceDiff) external onlyOwner {
    require(_maxPriceDiff <= 2e17, "UniswapV2PairPriceOracle: should <= 20%");

    maxPriceDiff = _maxPriceDiff;

    emit UpdateMaxPriceDiff(_maxPriceDiff);
  }

  function _validate(
    address _pair,
    address _ald,
    address _otherToken,
    uint256 _reserveALD,
    uint256 _reserveOtherToken
  ) internal view {
    address _twap = twaps[_pair];
    // skip check if twap not available, usually will be used in test.
    if (_twap == address(0)) return;

    // number of other token that 1 ald can swap right now.
    uint256 _amount = _reserveOtherToken.mul(1e18).div(_reserveALD);
    // number of other token that 1 ald can swap in twap.
    (uint256 _twapAmount, ) = IUniswapTWAPOracle(_twap).quote(_ald, 1e18, _otherToken, 2);

    require(_amount >= _twapAmount.mul(1e18 - maxPriceDiff).div(1e18), "UniswapV2PairPriceOracle: price too small");
    require(_amount <= _twapAmount.mul(1e18 + maxPriceDiff).div(1e18), "UniswapV2PairPriceOracle: price too large");
  }
}
