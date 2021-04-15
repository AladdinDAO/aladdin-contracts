pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/Address.sol";
import "../common/SafeERC20.sol";
import "../common/ERC20.sol";
import "../common/ReentrancyGuard.sol";

// A funding contract that allows purchase of shares
contract DAO is ERC20("Aladdin DAO Token", "ALDDAO"), ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;

    IERC20 public want;
    uint public rate; // wants per share. Need to correlate with want decimal place
    uint public shareCap;

    mapping(address => bool) public isWhitelisted;
    address[] public whitelist;

    mapping(address => uint) public shares; // Tracking of shares of funders to avoid going over sharesCap

    mapping(address => bool) public allowTransferFrom;
    mapping(address => bool) public allowTransferTo;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _want,
        uint _rate,
        uint _shareCap,
        address[] memory _whitelist
    )
        public
    {
        _setupDecimals(0);
        want = IERC20(_want);
        rate = _rate;
        shareCap = _shareCap;
        whitelist = _whitelist;

        for (uint i=0; i<_whitelist.length; i++) {
            isWhitelisted[_whitelist[i]] = true;
        }

        governance = msg.sender;
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

    /* ========== MUTATIVE FUNCTIONS ========== */

    // fund the dao and get shares
    function fund(uint _shares) external nonReentrant onlyWhitelist {
        require(shares[msg.sender].add(_shares) <= shareCap, "!over cap");

        uint w = _shares.mul(rate);
        want.safeTransferFrom(msg.sender, address(this), w);

        _mint(msg.sender, _shares);
        shares[msg.sender] = shares[msg.sender].add(_shares);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function whitelistLength() external view returns (uint256) {
        return whitelist.length;
    }

    function holdings(address _token)
        public
        view
        returns (uint)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // Silence warnings
        amount;

        // allow mint and burn
        if (from == address(0) || to == address(0)) {
            return;
        }

        // either sender or recipient needs to be whitelisted for transfer
        require(allowTransferFrom[from] == true || allowTransferTo[to] == true, "transfer not allowed");
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Creates `_amount` token to `_to`. Must only be called by minter
    function mint(address _to, uint256 _amount) external onlyGov {
        _mint(_to, _amount);
    }

    /// @notice Burn `_amount` token from `_from`. Must only be called by governance
    function burn(address _from, uint256 _amount) external onlyGov {
        _burn(_from, _amount);
    }

    function takeOut(
        address _token,
        address _destination,
        uint _amount
    )
        external
        onlyGov
    {
        require(_amount <= holdings(_token), "!insufficient");
        SafeERC20.safeTransfer(IERC20(_token), _destination, _amount);
    }

    function setGov(address _governance)
        external
        onlyGov
    {
        governance = _governance;
    }

    function setWant(address _want)
        external
        onlyGov
    {
        want = IERC20(_want);
    }

    function setRate(uint _rate)
        external
        onlyGov
    {
        rate = _rate;
    }

    function setShareCap(uint _shareCap)
        external
        onlyGov
    {
        shareCap = _shareCap;
    }

    function setAllowTransferFrom(address _addr, bool _bool)
        external
        onlyGov
    {
        allowTransferFrom[_addr] = _bool;
    }

    function setAllowTransferTo(address _addr, bool _bool)
        external
        onlyGov
    {
        allowTransferTo[_addr] = _bool;
    }

    function addToWhitelist(address _user)
        external
        onlyGov
    {
        require(isWhitelisted[_user] == false, "already in whitelist");
        isWhitelisted[_user] = true;
        whitelist.push(_user);
    }

    function removeFromWhitelist(address _user)
        external
        onlyGov
    {
        require(isWhitelisted[_user] == true, "not in whitelist");
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
}
