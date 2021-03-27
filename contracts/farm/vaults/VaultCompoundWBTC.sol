pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCompoundWBTC is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599), // WBTC
          address(0xc00e94Cb662C3520282E6f5717214004A7f26888), // comp
          _controller,
          _tokenMaster
        )
    {}
}
