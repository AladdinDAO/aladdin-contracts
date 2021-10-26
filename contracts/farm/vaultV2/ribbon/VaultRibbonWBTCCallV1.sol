// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseRibbonVaultV1.sol";

contract VaultRibbonWBTCCallV1 is BaseRibbonVaultV1 {
  constructor(address _treasury, address _tokenMaster)
    public
    BaseRibbonVaultV1(
      address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
      address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599), // WBTC
      address(0), // no reward token yet
      _treasury,
      _tokenMaster,
      IRibbonThetaVault(0x8b5876f5B0Bf64056A89Aa7e97511644758c3E8c) // Ribbon Finance: ThetaVault WBTC Call
    )
  {}
}
