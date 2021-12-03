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

  event UpdateRewardRate(uint256 rewardRate);

  uint256 private constant PRECISION = 1e18;

  // The address of ALD token.
  address public immutable ald;
  // The address of Aladdin Treasury.
  address public immutable treasury;
  // The address of Aladdin Staking Contract.
  address public immutable staking;

  // The reward rate for each rebase. Multipled by 1e18
  uint256 public rewardRate;

  /// @param _ald The address of ALD token.
  /// @param _treasury The address of Aladdin Treasury.
  /// @param _staking The address of Aladdin Staking contract.
  constructor(
    address _ald,
    address _treasury,
    address _staking
  ) {
    require(_ald != address(0), "Treasury: zero address");
    require(_treasury != address(0), "Treasury: zero address");
    require(_staking != address(0), "Treasury: zero address");

    ald = _ald;
    treasury = _treasury;
    staking = _staking;

    rewardRate = 3e15; // 0.3%
  }

  /// @dev distribute ALD reward to Aladdin Staking contract.
  function distribute() external override {
    require(msg.sender == staking, "Distributor: not approved");

    uint256 _reward = nextRewardAt(rewardRate);
    ITreasury(treasury).mintRewards(staking, _reward);
  }

  /// @dev return the rewarded ALD amount given reward rate.
  /// @param _rate reward rate.
  function nextRewardAt(uint256 _rate) public view returns (uint256) {
    return IERC20(ald).totalSupply().mul(_rate).div(PRECISION);
  }

  /// @dev Update the reward rate.
  /// @param _rewardRate The new reward rate.
  function updateRewardRate(uint256 _rewardRate) external onlyOwner {
    require(_rewardRate <= PRECISION, "Distributor: reward rate too large");

    rewardRate = _rewardRate;

    emit UpdateRewardRate(_rewardRate);
  }
}
