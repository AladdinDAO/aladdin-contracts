pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCompoundWETH is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
          address(0xc00e94Cb662C3520282E6f5717214004A7f26888), // comp
          _controller,
          _tokenMaster
        )
    {}
}
