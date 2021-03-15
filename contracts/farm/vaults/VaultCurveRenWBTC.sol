pragma solidity 0.6.12;

import "./BaseVault.sol";

contract VaultCurveRenWBTC is BaseVault {
    constructor (
          address _controller,
          address _tokenMaster)
        public
        BaseVault(
          address(0x49849C98ae39Fff122806C06791Fa73784FB3675), // crvRenWBTC
          address(0xD533a949740bb3306d119CC777fa900bA034cd52), // crv
          _controller,
          _tokenMaster
        )
    {}
}
