// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IWXALD {
  function wrap(uint256 _xALDAmount) external returns (uint256);

  function unwrap(uint256 _wxALDAmount) external returns (uint256);

  function wrappedXALDToXALD(uint256 _wxALDAmount) external view returns (uint256);
}
