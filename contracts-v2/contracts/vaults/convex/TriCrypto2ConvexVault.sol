// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./BaseConvexVault.sol";

contract TriCrypto2ConvexVault is BaseConvexVault {
  constructor(address _depositor, address _governor)
    BaseConvexVault(
      address(0xc4AD29ba4B3c580e6D59105FFf484999997675Ff), // 3CrvCrypto2
      _depositor,
      _governor,
      address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Finance: Booster,
      38 // pid
    )
  {
    address[] memory _rewardTokens = new address[](2);
    _rewardTokens[0] = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV
    _rewardTokens[1] = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B); // CVX

    _setupRewardTokens(_rewardTokens);
  }
}
