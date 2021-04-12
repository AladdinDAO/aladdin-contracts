pragma solidity 0.6.12;

import "../common/ERC20.sol";

// Standard ERC20 token with mint and burn. Governance can pause transfer
contract VoteToken is ERC20("Aladdin Vote Token", "ALDVOTE") {
    address public governance;
    mapping (address => bool) public isMinter;
    bool public paused;

    constructor () public {
        _setupDecimals(0);
        paused = true;
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

    function pause() public {
        require(msg.sender == governance, "!governance");
        paused = true;
    }

    function unpause() public {
        require(msg.sender == governance, "!governance");
        paused = false;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by minter
    function mint(address _to, uint256 _amount) public {
        require(isMinter[msg.sender] == true, "!minter");
        _mint(_to, _amount);
    }

    /// @notice Burn `_amount` token from `_from`. Must only be called by governance
    function burn(address _from, uint256 _amount) public {
        require(msg.sender == governance, "!governance");
        _burn(_from, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // Silence warnings
        amount;

        // allow mint and burn
        if (from == address(0) || to == address(0)) {
            return;
        }

        require(!paused, "paused");
    }
}
