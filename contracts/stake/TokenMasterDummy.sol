pragma solidity 0.6.12;

import "../common/ERC20.sol";

contract TokenMasterDummy is ERC20("TokenMaster Dummy For xALD", "xALDDummy") {
    constructor () public {
        _mint(msg.sender, 10000 * 1e18); // mint 10000 tokens to avoid potential rounding error
    }
}
