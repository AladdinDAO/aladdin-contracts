// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MockStaking {
  using SafeERC20 for IERC20;

  address public ald;

  constructor(address _ald) {
    ald = _ald;
  }

  function bondFor(address, uint256 _amount) external {
    IERC20(ald).safeTransferFrom(msg.sender, address(this), _amount);
  }

  function rewardBond(address, uint256 _amount) external {
    IERC20(ald).safeTransferFrom(msg.sender, address(this), _amount);
  }

  function rebase() external {}
}
