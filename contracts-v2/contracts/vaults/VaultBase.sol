// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IVault.sol";

abstract contract VaultBase is ReentrancyGuard, IVault {
  uint256 public constant PRECISION = 1e18;

  // The address of staked token.
  address public immutable baseToken;
  // The address of reward bond depositor.
  address public depositor;

  // The address of governor.
  address public governor;

  // The percentage take from harvested reward to bond.
  uint256 public bondPercentage;

  // The total share of vault.
  uint256 public override balance;
  // Mapping from user address to vault share.
  mapping(address => uint256) public override balanceOf;

  modifier onlyGovernor() {
    require(msg.sender == governor, "VaultBase: only governor");
    _;
  }

  constructor(
    address _baseToken,
    address _depositor,
    address _governor
  ) {
    baseToken = _baseToken;
    depositor = _depositor;
    governor = _governor;

    bondPercentage = PRECISION;
  }

  function setGovernor(address _governor) external onlyGovernor {
    governor = _governor;
  }

  function setBondPercentage(uint256 _bondPercentage) external onlyGovernor {
    require(_bondPercentage <= PRECISION, "VaultBase: percentage too large");

    bondPercentage = _bondPercentage;
  }
}
