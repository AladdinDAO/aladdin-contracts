pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCurveHBTC is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0xb19059ebb43466C323583928285a49f558E572Fd), // hCRV
          address(0xD533a949740bb3306d119CC777fa900bA034cd52), // crv
          _controller,
          _tokenMaster
        )
    {}
}
