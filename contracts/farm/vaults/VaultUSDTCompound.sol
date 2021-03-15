pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultUSDTCompound is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0x07de306FF27a2B630B1141956844eB1552B956B5), // USDT
          address(0x61460874a7196d6a22D1eE4922473664b3E95270), // comp
          _controller,
          _tokenMaster
        )
    {}
}
