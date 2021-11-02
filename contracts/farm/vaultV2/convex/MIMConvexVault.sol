// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseConvexVault.sol";

contract MIMConvexVault is BaseConvexVault {
  constructor(address _treasury, address _tokenMaster)
    public
    BaseConvexVault(
      address(0x5a6A4D54456819380173272A5E8E9B9904BdF41B), // mimCrv
      _treasury,
      _tokenMaster,
      address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Finance: Booster,
      40 // pid
    )
  {
    address[] memory _rewardTokens = new address[](3);
    _rewardTokens[0] = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV
    _rewardTokens[1] = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B); // CVX
    _rewardTokens[2] = address(0x69a92f1656cd2e193797546cFe2EaF32EACcf6f7); // SPELL

    _setupRewardTokens(_rewardTokens);
  }
}
