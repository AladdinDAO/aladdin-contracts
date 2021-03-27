pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultSushiETHWBTC is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58), // ETHWBTClp
          address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
          _controller,
          _tokenMaster
        )
    {}
}
