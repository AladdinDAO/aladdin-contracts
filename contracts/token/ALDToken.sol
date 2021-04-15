pragma solidity 0.6.12;

import "../common/ERC20.sol";

// Standard ERC20 token with mint and burn
contract ALDToken is ERC20("Aladdin Token", "ALD") {
    address public governance;
    mapping (address => bool) public isMinter;

    constructor () public {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setMinter(address _minter, bool _status) external {
        require(msg.sender == governance, "!governance");
        isMinter[_minter] = _status;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by minter
    function mint(address _to, uint256 _amount) external {
        require(isMinter[msg.sender] == true, "!minter");
        _mint(_to, _amount);
    }

    /// @notice Burn `_amount` token from `_from`. Must only be called by governance
    function burn(address _from, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        _burn(_from, _amount);
    }
}
