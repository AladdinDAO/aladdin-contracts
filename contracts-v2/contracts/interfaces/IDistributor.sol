// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IDistributor {
  /// @dev distribute ALD reward to Aladdin Staking contract.
  function distribute() external;
}
