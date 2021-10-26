// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseRibbonVaultV1.sol";

contract VaultRibbonETHCallV1 is BaseRibbonVaultV1 {
  constructor(address _treasury, address _tokenMaster)
    public
    BaseRibbonVaultV1(
      address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
      address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
      address(0), // no reward token yet
      _treasury,
      _tokenMaster,
      IRibbonThetaVault(0x0FABaF48Bbf864a3947bdd0Ba9d764791a60467A) // Ribbon Finance: ThetaVault ETH Call
    )
  {}
}
