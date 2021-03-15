pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCurveSETH is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c), // crvSETH
          address(0xD533a949740bb3306d119CC777fa900bA034cd52), // crv
          _controller,
          _tokenMaster
        )
    {}
}
