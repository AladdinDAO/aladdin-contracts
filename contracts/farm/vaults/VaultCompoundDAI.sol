pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCompoundDAI is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0x6B175474E89094C44Da98b954EedeAC495271d0F), // DAI
          address(0xc00e94Cb662C3520282E6f5717214004A7f26888), // comp
          _controller,
          _tokenMaster
        )
    {}
}
