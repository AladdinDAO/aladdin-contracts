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

    /* ========== STRUCTS ========== */

    struct Lock {
        uint locked;
        uint unlockTime;
    }

    /* ========== STATE VARIABLES ========== */

    address public governance;

    IERC20 public ald;
    uint256 public stakeAmount; // amount of ALD to stake to gain aldplus status

    // only whitelisted address can stake
    bool public enableWhitelist = true;
    mapping(address => bool) public isWhitelisted;
    address[] public whitelist;

    // aldplus shares, each address should only have one share
    mapping(address => uint) public shares; // this technically can be binary, but using uint for balance
    mapping(address => uint) public balance; // address => staked balance

    uint private constant LOCK_DURATION = 14 days;
    mapping(address => Lock) public locks; // address => locks

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

    // Stake ALD to receive ALDPLUS shares
    function stake() external nonReentrant onlyWhitelist {
        require(locks[msg.sender].locked == 0, "!unlocked");
        require(shares[msg.sender] == 0, "already staked");
        ald.safeTransferFrom(msg.sender, address(this), stakeAmount);
        balance[msg.sender] = balance[msg.sender].add(stakeAmount);
        shares[msg.sender] = 1;
        emit Stake(msg.sender, stakeAmount);
    }

    // Unstake ALD burns ALDPLUS shares and locks ALD for lock duration
    function unstake() external nonReentrant {
        require(shares[msg.sender] != 0, "!staked");
        uint256 _balance = balance[msg.sender];
        balance[msg.sender] = 0;
        shares[msg.sender] = 0;
        // lock
        locks[msg.sender].locked = _balance;
        locks[msg.sender].unlockTime = block.timestamp.add(LOCK_DURATION);
        emit Unstake(msg.sender, _balance);
    }

    // Withdraw unlocked ALDs
    function withdraw() external nonReentrant {
        require(locks[msg.sender].locked > 0, "!locked");
        require(locks[msg.sender].unlockTime >= block.timestamp, "!unlocked");
        uint256 _locked = locks[msg.sender].locked;
        // unlock
        locks[msg.sender].locked = 0;
        locks[msg.sender].unlockTime = 0;
        ald.safeTransfer(msg.sender, _locked);
        emit Withdrawn(msg.sender, _locked);
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

    function setEnableWhitelist()
        external
        onlyGov
    {
        enableWhitelist = true;
    }

    function setDisableWhitelist()
        external
        onlyGov
    {
        enableWhitelist = false;
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

    // Allow governance to rescue stuck tokens
    function rescue(address _token)
        external
        onlyGov
    {
        require(_token != address(ald), "!ald");
        uint _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(governance, _balance);
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier onlyWhitelist() {
        if (enableWhitelist) {
            require(isWhitelisted[msg.sender] == true, "!whitelist");
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Stake(address _user, uint256 _amount);
    event Unstake(address _user, uint256 _amount);
    event Withdrawn(address _user, uint256 _amount);
}
