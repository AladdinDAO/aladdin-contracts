// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IERC20Metadata.sol";

contract ChainlinkPriceOracle is Ownable, IPriceOracle {
  using SafeMath for uint256;

  mapping(address => AggregatorV3Interface) public feeds;

  function price(address _asset) public view override returns (uint256) {
    AggregatorV3Interface _feed = feeds[_asset];
    uint8 _decimals = _feed.decimals();
    (, int256 _price, , , ) = _feed.latestRoundData();
    return uint256(_price).mul(1e18).div(10**_decimals);
  }

  function value(address _asset, uint256 _amount) external view override returns (uint256) {
    uint256 _price = price(_asset);
    return _price.mul(_amount).div(10**IERC20Metadata(_asset).decimals());
  }

  function updateFeed(address _token, AggregatorV3Interface _feed) external onlyOwner {
    feeds[_token] = _feed;
  }
}
