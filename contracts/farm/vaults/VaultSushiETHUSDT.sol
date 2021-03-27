pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultSushiETHUSDT is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0x06da0fd433C1A5d7a4faa01111c044910A184553), // ETHUSDTlp
          address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
          _controller,
          _tokenMaster
        )
    {}
}
