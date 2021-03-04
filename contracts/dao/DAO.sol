pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/Address.sol";
import "../common/SafeERC20.sol";
import "../common/ERC20.sol";

// A funding contract that allows purchase of shares
contract DAO is ERC20 {
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

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _want,
        uint _rate,
        uint _shareCap,
        address[] memory _whitelist
    )
        public
        ERC20 (
          string(abi.encodePacked("Aladdin DAO")),
          string(abi.encodePacked("aDAO"))
        )
    {
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
    function fund(uint _shares) external onlyWhitelist {
        require(balanceOf(msg.sender).add(_shares) <= shareCap, "!over cap");

        uint w = _shares.mul(rate);
        want.safeTransferFrom(msg.sender, address(this), w);

        _mint(msg.sender, _shares);
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

    /* ========== RESTRICTED FUNCTIONS ========== */

    function takeOut(
        address _token,
        address _destination,
        uint _amount
    )
        public
        onlyGov
    {
        require(_amount <= holdings(_token), "!insufficient");
        SafeERC20.safeTransfer(IERC20(_token), _destination, _amount);
    }

    function setGov(address _governance)
        public
        onlyGov
    {
        governance = _governance;
    }

    function setWant(address _want)
        public
        onlyGov
    {
        want = IERC20(_want);
    }

    function setRate(uint _rate)
        public
        onlyGov
    {
        rate = _rate;
    }

    function setShareCap(uint _shareCap)
        public
        onlyGov
    {
        shareCap = _shareCap;
    }

    function addToWhitelist(address _user)
        public
        onlyGov
    {
        require(isWhitelisted[_user] == false, "already in whitelist");
        isWhitelisted[_user] = true;
        whitelist.push(_user);
    }

    function removeFromWhitelist(address _user)
        public
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
