pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/SafeERC20.sol";
import "../common/ERC20.sol";
import "../common/ReentrancyGuard.sol";

// Stake ALD to gain ALDPlus shares
contract ALDPlus is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;

    IERC20 public ald;

    mapping(address => bool) public isWhitelisted;
    address[] public whitelist;

    mapping(address => uint) public shares; // Tracking of shares of funders to avoid going over sharesCap

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20 _ald
    )
        public
    {
        ald = _ald;
        governance = msg.sender;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) external nonReentrant onlyWhitelist {
        ald.safeTransferFrom(msg.sender, address(this), _amount);
        shares[msg.sender] = shares[msg.sender].add(_amount);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint _amount) external nonReentrant {
        require(shares[msg.sender] >= _amount, "not enough shares");
        shares[msg.sender] = shares[msg.sender].sub(_amount);
        ald.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function whitelistLength() external view returns (uint256) {
        return whitelist.length;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setGov(address _governance)
        external
        onlyGov
    {
        governance = _governance;
    }

    function addToWhitelist(address _user)
        external
        onlyGov
    {
        require(!isWhitelisted[_user], "already in whitelist");
        isWhitelisted[_user] = true;
        whitelist.push(_user);
    }

    function removeFromWhitelist(address _user)
        external
        onlyGov
    {
        require(isWhitelisted[_user], "not in whitelist");
        isWhitelisted[_user] = false;

        // find the index
        uint indexToDelete = 0;
        bool found = false;
        for (uint i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _user) {
                indexToDelete = i;
                found = true;
                break;
            }
        }

        // remove element
        require(found == true, "user not found in whitelist");
        whitelist[indexToDelete] = whitelist[whitelist.length - 1];
        whitelist.pop();
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier onlyWhitelist() {
        require(isWhitelisted[msg.sender] == true, "!whitelist");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address _user, uint256 _amount);
    event Withdraw(address _user, uint256 _amount);
}
