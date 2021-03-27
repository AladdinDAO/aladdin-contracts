pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCurve3Pool is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490), // 3Crv
          address(0xD533a949740bb3306d119CC777fa900bA034cd52), // crv
          _controller,
          _tokenMaster
        )
    {}
}
