pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/Address.sol";
import "../common/SafeERC20.sol";

// A simple treasury that takes erc20 tokens and ETH
contract Treasury {

    /* ========== STATE VARIABLES ========== */

    address public governance;

    /* ========== CONSTRUCTOR ========== */

    constructor() public {
        governance = msg.sender;
    }

     // accepts ether
    receive() external payable{}
    fallback() external payable{}

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance, "!gov");
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
        external
        onlyGov
    {
        require(_amount <= holdings(_token), "!insufficient");
        SafeERC20.safeTransfer(IERC20(_token), _destination, _amount);
    }

    function takeOutETH(
        address payable _destination,
        uint256 _amount
    )
        external
        payable
        onlyGov
    {
        _destination.transfer(_amount);
    }

    function setGov(address _governance)
        external
        onlyGov
    {
        governance = _governance;
    }
}
