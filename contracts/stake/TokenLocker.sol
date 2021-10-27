pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/SafeERC20.sol";
import "../interfaces/ITokenLocker.sol";

// Locks transfered tokens for a recipient for a set amount of period
contract TokenLocker is ITokenLocker {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STRUCTS ========== */

    struct Lock {
        uint amount;
        uint unlockTime;
    }

    /* ========== STATE VARIABLES ========== */

    // Address states
    address public governance;
    mapping(address => bool) public isManager;
    IERC20 public token;

    // Lock states
    uint public lockDuration;
    mapping(address => Lock) public locks; // user address => Lock

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20 _token,
        uint _lockDuration
    )
        public
    {
        token = _token;
        lockDuration = _lockDuration;
        governance = msg.sender;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function lockedBalance(address _user) external view returns (uint) {
        return locks[_user].amount;
    }

    function lockedUntil(address _user) external view returns (uint) {
        return locks[_user].unlockTime;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Transfer token from sender and lock for recipient
    function lock(uint _amount, address _recipient) external override onlyManager {
        // transfer token
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Update lock. A new lock will refresh existing unlock time
        locks[_recipient].amount = locks[_recipient].amount.add(_amount);
        locks[_recipient].unlockTime = block.timestamp.add(lockDuration);

        emit Locked(_recipient, _amount, locks[_recipient].unlockTime);
    }

    // Withdraw unlocked
    function withdraw() external {
        require(locks[msg.sender].amount > 0, "!locked");
        require(block.timestamp >= locks[msg.sender].unlockTime, "!unlocked");

        // withdraw and reset lock
        uint256 _amount = locks[msg.sender].amount;
        locks[msg.sender].amount = 0;
        locks[msg.sender].unlockTime = 0;

        token.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setGov(address _governance)
        external
        onlyGov
    {
        governance = _governance;
    }

    function addManager(address _manager)
        external
        onlyGov
    {
        isManager[_manager] = true;
    }

    function removeManager(address _manager)
        external
        onlyGov
    {
        isManager[_manager] = false;
    }

    function setLockDuration(uint _lockDuration)
        external
        onlyGov
    {
        lockDuration = _lockDuration;
    }

    // Allow governance to rescue stuck tokens
    function rescue(address _token)
        external
        onlyGov
    {
        require(_token != address(token), "cannot withdraw user locked tokens");
        uint _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(governance, _balance);
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier onlyManager() {
        require(isManager[msg.sender], "!manager");
        _;
    }

    /* ========== EVENTS ========== */

    event UpdateManager(address _manager, bool _status);
    event Locked(address _user, uint _amount, uint _unlockTime);
    event Withdrawn(address _user, uint256 _amount);
}
