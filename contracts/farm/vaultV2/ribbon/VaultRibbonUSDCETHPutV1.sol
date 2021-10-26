// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseRibbonVaultV1.sol";

contract VaultRibbonUSDCETHPutV1 is BaseRibbonVaultV1 {
  constructor(address _treasury, address _tokenMaster)
    public
    BaseRibbonVaultV1(
      address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
      address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), // USDC
      address(0), // no reward token yet
      _treasury,
      _tokenMaster,
      IRibbonThetaVault(0x16772a7f4a3ca291C21B8AcE76F9332dDFfbb5Ef) // Ribbon Finance: ThetaVault ETH Put
    )
  {}
}
