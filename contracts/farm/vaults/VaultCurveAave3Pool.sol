pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCurveAave3Pool is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900), // a3CRV
          address(0xD533a949740bb3306d119CC777fa900bA034cd52), // crv
          _controller,
          _tokenMaster
        )
    {}
}
