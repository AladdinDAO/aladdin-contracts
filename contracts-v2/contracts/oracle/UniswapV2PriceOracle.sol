// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IERC20Metadata.sol";

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
}

contract UniswapV2PriceOracle is Ownable, IPriceOracle {
  using SafeMath for uint256;

  // The address of Chainlink Oracle
  address public immutable chainlink;

  // The address base token.
  address public immutable base;

  mapping(address => address) pairs;

  constructor(address _chainlink, address _base) {
    require(_chainlink != address(0), "UniswapV2PriceOracle: zero address");
    require(_base != address(0), "UniswapV2PriceOracle: zero address");

    chainlink = _chainlink;
    base = _base;
  }

  function price(address _asset) public view override returns (uint256) {
    address _pair = pairs[_asset];
    require(_pair != address(0), "UniswapV2PriceOracle: not supported");

    uint256 _basePrice = IPriceOracle(chainlink).price(base);
    (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(_pair).getReserves();
    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();

    // make reserve with scale 1e18
    if (IERC20Metadata(_token0).decimals() < 18) {
      _reserve0 = _reserve0.mul(10**IERC20Metadata(_token0).decimals());
    }
    if (IERC20Metadata(_token1).decimals() < 18) {
      _reserve1 = _reserve1.mul(10**IERC20Metadata(_token1).decimals());
    }

    if (_asset == _token0) {
      return _basePrice.mul(_reserve1).div(_reserve0);
    } else {
      return _basePrice.mul(_reserve0).div(_reserve1);
    }
  }

  function value(address _asset, uint256 _amount) external view override returns (uint256) {
    uint256 _price = price(_asset);
    return _price.mul(_amount).div(10**IERC20Metadata(_asset).decimals());
  }

  function updatePair(address _asset, address _pair) external onlyOwner {
    address _base = base;
    require(_base != _asset, "UniswapV2PriceOracle: invalid asset");

    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();
    require(_token0 == _asset || _token1 == _asset, "UniswapV2PriceOracle: invalid pair");
    require(_token0 == base || _token1 == base, "UniswapV2PriceOracle: invalid pair");

    pairs[_asset] = _pair;
  }
}
