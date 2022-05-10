// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseConvexVault.sol";

contract TriPoolConvexVault is BaseConvexVault {
  constructor(address _depositor, address _governor)
    BaseConvexVault(
      address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490), // 3poolCrv
      _depositor,
      _governor,
      address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Finance: Booster,
      9 // pid
    )
  {
    address[] memory _rewardTokens = new address[](2);
    _rewardTokens[0] = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV
    _rewardTokens[1] = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B); // CVX

    _setupRewardTokens(_rewardTokens);
  }
}
