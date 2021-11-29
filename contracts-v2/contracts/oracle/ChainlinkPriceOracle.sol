// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IERC20Metadata.sol";

contract ChainlinkPriceOracle is Ownable, IPriceOracle {
  using SafeMath for uint256;

  event UpdateFeed(address indexed asset, AggregatorV3Interface feed);

  // Mapping from asset address to chainlink aggregator.
  mapping(address => AggregatorV3Interface) public feeds;

  /// @dev Return the usd price of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  function price(address _asset) public view override returns (uint256) {
    AggregatorV3Interface _feed = feeds[_asset];
    require(address(_feed) != address(0), "ChainlinkPriceOracle: not supported");

    uint8 _decimals = _feed.decimals();
    (, int256 _price, , , ) = _feed.latestRoundData();
    return uint256(_price).mul(1e18).div(10**_decimals);
  }

  /// @dev Return the usd value of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  /// @param _amount The amount of asset
  function value(address _asset, uint256 _amount) external view override returns (uint256) {
    uint256 _price = price(_asset);
    return _price.mul(_amount).div(10**IERC20Metadata(_asset).decimals());
  }

  /// @dev Update chainlink aggregator for asset
  /// @param _asset The address of asset to update.
  /// @param _feed The chainlink aggregator.
  function updateFeed(address _asset, AggregatorV3Interface _feed) external onlyOwner {
    require(address(_feed) != address(0), "ChainlinkPriceOracle: zero address");

    feeds[_asset] = _feed;

    emit UpdateFeed(_asset, _feed);
  }
}
