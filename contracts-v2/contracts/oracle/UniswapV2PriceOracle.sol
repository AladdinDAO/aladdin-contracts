// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract UniswapV2PriceOracle is Ownable, IPriceOracle {
  using SafeMath for uint256;

  event UpdatePair(address indexed asset, address pair);

  // The address of Chainlink Oracle
  address public immutable chainlink;

  // The address base token.
  address public immutable base;

  // Mapping from asset address to uniswap v2 like pair.
  mapping(address => address) public pairs;

  /// @param _chainlink The address of chainlink oracle.
  /// @param _base The address of base token.
  constructor(address _chainlink, address _base) {
    require(_chainlink != address(0), "UniswapV2PriceOracle: zero address");
    require(_base != address(0), "UniswapV2PriceOracle: zero address");

    chainlink = _chainlink;
    base = _base;
  }

  /// @dev Return the usd price of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  function price(address _asset) public view override returns (uint256) {
    address _pair = pairs[_asset];
    require(_pair != address(0), "UniswapV2PriceOracle: not supported");

    uint256 _basePrice = IPriceOracle(chainlink).price(base);
    (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(_pair).getReserves();
    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();

    // make reserve with scale 1e18
    if (IERC20Metadata(_token0).decimals() < 18) {
      _reserve0 = _reserve0.mul(10**(18 - IERC20Metadata(_token0).decimals()));
    }
    if (IERC20Metadata(_token1).decimals() < 18) {
      _reserve1 = _reserve1.mul(10**(18 - IERC20Metadata(_token1).decimals()));
    }

    if (_asset == _token0) {
      return _basePrice.mul(_reserve1).div(_reserve0);
    } else {
      return _basePrice.mul(_reserve0).div(_reserve1);
    }
  }

  /// @dev Return the usd value of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  /// @param _amount The amount of asset
  function value(address _asset, uint256 _amount) external view override returns (uint256) {
    uint256 _price = price(_asset);
    return _price.mul(_amount).div(10**IERC20Metadata(_asset).decimals());
  }

  /// @dev Update the UniswapV2 pair for asset
  /// @param _asset The address of asset
  /// @param _pair The address of UniswapV2 pair
  function updatePair(address _asset, address _pair) external onlyOwner {
    require(_pair != address(0), "UniswapV2PriceOracle: invalid pair");

    address _base = base;
    require(_base != _asset, "UniswapV2PriceOracle: invalid asset");

    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();
    require(_token0 == _asset || _token1 == _asset, "UniswapV2PriceOracle: invalid pair");
    require(_token0 == base || _token1 == base, "UniswapV2PriceOracle: invalid pair");

    pairs[_asset] = _pair;

    emit UpdatePair(_asset, _pair);
  }
}
