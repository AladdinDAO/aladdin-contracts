// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXALD is IERC20 {
  function stake(address _recipient, uint256 _aldAmount) external;

  function unstake(address _account, uint256 _xALDAmount) external;

  function rebase(uint256 epoch, uint256 profit) external;

  function getSharesByALD(uint256 _aldAmount) external view returns (uint256);

  function getALDByShares(uint256 _sharesAmount) external view returns (uint256);
}
