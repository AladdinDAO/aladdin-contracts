// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseConvexVault.sol";

contract STETHConvexVault is BaseConvexVault {
  constructor(address _treasury, address _tokenMaster)
    public
    BaseConvexVault(
      address(0x06325440D014e39736583c165C2963BA99fAf14E), // stethCRV
      _treasury,
      _tokenMaster,
      address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Finance: Booster,
      25 // pid
    )
  {
    address[] memory _rewardTokens = new address[](3);
    _rewardTokens[0] = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV
    _rewardTokens[1] = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B); // CVX
    _rewardTokens[2] = address(0x008aEa5036b819B4FEAEd10b2190FBb3954981E8); // LDO

    _setupRewardTokens(_rewardTokens);
  }
}
