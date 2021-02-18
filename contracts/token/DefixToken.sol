pragma solidity 0.6.12;

import "../common/ERC20.sol";

// Standard ERC20 token with minter role
contract DefixToken is ERC20("DefixToken", "DEFIX") {
    address public governance;
    mapping (address => bool) public isMinter;

    constructor () public {
        governance = msg.sender;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setMinter(address _minter, bool _status) public {
        require(msg.sender == governance, "!governance");
        isMinter[_minter] = _status;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by minter
    function mint(address _to, uint256 _amount) public {
        require(isMinter[msg.sender] == true, "!minter");
        _mint(_to, _amount);
    }
}
