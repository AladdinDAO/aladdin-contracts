pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultSushiETHUSDC is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0), // ETHUSDClp
          address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
          _controller,
          _tokenMaster
        )
    {}
}
