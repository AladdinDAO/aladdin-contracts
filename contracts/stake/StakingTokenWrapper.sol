// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "../common/ERC20.sol";

// Dummy wrapper to direct reward from token master to beneficiary
// The beneficiary is the sole holder of a dummy token staked in the TokenMaster
contract StakingTokenWrapper is ERC20("TokenMaster Staking Wrapper", "TSW") {
    address public beneficiary;

    constructor(address _beneficiary) public {
        beneficiary = _beneficiary;
        uint256 amount = 1e18;
        _mint(_beneficiary, amount);
    }
}
