pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCompoundUSDT is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0xdAC17F958D2ee523a2206206994597C13D831ec7), // USDT
          address(0xc00e94Cb662C3520282E6f5717214004A7f26888), // comp
          _controller,
          _tokenMaster
        )
    {}
}
