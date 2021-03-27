pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCompoundUSDC is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), // USDC
          address(0xc00e94Cb662C3520282E6f5717214004A7f26888), // comp
          _controller,
          _tokenMaster
        )
    {}
}
