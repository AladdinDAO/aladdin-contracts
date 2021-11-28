// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IVault.sol";

abstract contract VaultBase is ReentrancyGuard, IVault {
  uint256 public constant PRECISION = 1e18;

  address public immutable token;
  address public immutable depositor;

  address public governor;

  uint256 public bondPercentage;

  uint256 public override balance;
  mapping(address => uint256) public override balanceOf;

  modifier onlyGovernor() {
    require(msg.sender == governor, "VaultBase: only governor");
    _;
  }

  constructor(
    address _token,
    address _depositor,
    address _governor
  ) {
    token = _token;
    depositor = _depositor;
    governor = _governor;
  }

  function setGovernor(address _governor) external onlyGovernor {
    governor = _governor;
  }

  function setBondPercentage(uint256 _bondPercentage) external onlyGovernor {
    require(_bondPercentage <= PRECISION, "VaultBase: percentage too large");

    bondPercentage = _bondPercentage;
  }
}
