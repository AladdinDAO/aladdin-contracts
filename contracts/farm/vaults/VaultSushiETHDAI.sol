pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultSushiETHDAI is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f), // ETHDAIlp
          address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
          _controller,
          _tokenMaster
        )
    {}
}
