// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/IDistributor.sol";

contract Distributor is Ownable, IDistributor {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public PRECISION = 1e18;

  address public immutable ald;
  address public immutable treasury;
  address public immutable staking;

  uint256 public rewardRate;

  constructor(
    address _ald,
    address _treasury,
    address _staking,
    uint256 _rewardRate
  ) {
    require(_rewardRate <= PRECISION, "Distributor: reward rate too large");
    ald = _ald;
    treasury = _treasury;
    staking = _staking;
    rewardRate = _rewardRate;
  }

  function distribute() external override {
    require(msg.sender == staking, "Distributor: not approved");

    uint256 _reward = nextRewardAt(rewardRate);
    ITreasury(treasury).mintRewards(staking, _reward);
  }

  function nextRewardAt(uint256 _rate) public view returns (uint256) {
    return IERC20(ald).totalSupply().mul(_rate).div(PRECISION);
  }

  function updateRewardRate(uint256 _rewardRate) external onlyOwner {
    require(_rewardRate <= PRECISION, "Distributor: reward rate too large");

    rewardRate = _rewardRate;
  }
}
