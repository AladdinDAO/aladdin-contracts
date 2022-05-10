// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// distribute ald reward for dao to different recipient
contract DAODistributor is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public immutable ald;
  address public keeper;

  uint256 public length;
  mapping(uint256 => address) public recipients;
  mapping(uint256 => uint256) public percentage;

  constructor(address _ald, address _keeper) {
    require(_ald != address(0), "DAODistributor: zero address");
    require(_keeper != address(0), "DAODistributor: zero address");

    ald = _ald;
    keeper = _keeper;
  }

  function updateRecipients(address[] memory _recipients, uint256[] memory _percentage) external onlyOwner {
    require(_recipients.length == _percentage.length, "DAODistributor: length mismatch");

    uint256 sum = 0;
    for (uint256 i = 0; i < _recipients.length; i++) {
      for (uint256 j = 0; j < i; j++) {
        require(_recipients[i] != _recipients[j], "DAODistributor: duplicate recipient");
      }
      recipients[i] = _recipients[i];
      percentage[i] = _percentage[i];
      sum = sum.add(_percentage[i]);
    }

    require(sum == 1e18, "DAODistributor: sum should be 100%");
    length = _recipients.length;
  }

  function updateKeeper(address _keeper) external onlyOwner {
    require(_keeper != address(0), "DAODistributor: zero address");
    keeper = _keeper;
  }

  function distribute() external {
    require(msg.sender == keeper, "DAODistributor: only keeper");

    uint256 _balance = IERC20(ald).balanceOf(address(this));
    uint256 _length = length;
    for (uint256 i = 0; i < _length; i++) {
      uint256 _amount = _balance.mul(percentage[i]).div(1e18);
      if (_amount > 0) {
        IERC20(ald).safeTransfer(recipients[i], _amount);
      }
    }
  }
}
