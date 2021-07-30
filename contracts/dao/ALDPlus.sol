pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/SafeERC20.sol";
import "../common/ERC20.sol";
import "../common/ReentrancyGuard.sol";

// Stake ALD to gain ALDPlus status
contract ALDPlus is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;

    IERC20 public ald;
    uint256 public stakeAmount; // amount of ALD to stake to gain aldplus status

    // only whitelisted address can stake
    mapping(address => bool) public isWhitelisted;
    address[] public whitelist;

    // aldplus shares, each address should only have one share
    mapping(address => uint) public shares; // this technically can be binary, but using uint for balance
    mapping(address => uint) public balance; // track staked balance used on withdraw

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

    function stake() external nonReentrant onlyWhitelist {
        require(shares[msg.sender] == 0, "already staked");
        ald.safeTransferFrom(msg.sender, address(this), stakeAmount);
        balance[msg.sender] = balance[msg.sender].add(stakeAmount);
        shares[msg.sender] = 1;
        emit Stake(msg.sender, stakeAmount);
    }

    function unstake() external nonReentrant {
        require(shares[msg.sender] != 0, "!staked");
        uint256 _balance = balance[msg.sender];
        balance[msg.sender] = 0;
        shares[msg.sender] = 0;
        ald.safeTransfer(msg.sender, _balance);
        emit Unstake(msg.sender, _balance);
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

    function setStakeAmount(uint256 _stakeAmount)
        external
        onlyGov
    {
        stakeAmount = _stakeAmount;
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

    event Stake(address _user, uint256 _amount);
    event Unstake(address _user, uint256 _amount);
}
