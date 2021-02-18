pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/Address.sol";
import "../common/SafeERC20.sol";

// A simple treasury that takes erc20 tokens and ETH
contract DAOTreasury {

    /* ========== STATE VARIABLES ========== */

    address public governance;

    /* ========== CONSTRUCTOR ========== */

    constructor() public {
        governance = msg.sender;
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance);
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function holdings(address _token)
        public
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function takeOut(
        address _token,
        address _destination,
        uint256 _amount
    )
        public
        onlyGov
    {
        require(_amount <= holdings(_token), "!insufficient");
        SafeERC20.safeTransfer(IERC20(_token), _destination, _amount);
    }

    function takeOutETH(
        address payable _destination,
        uint256 _amount
    )
        public
        payable
        onlyGov
    {
        _destination.transfer(_amount);
    }

    function setGov(address _governance)
        public
        onlyGov
    {
        governance = _governance;
    }
}
