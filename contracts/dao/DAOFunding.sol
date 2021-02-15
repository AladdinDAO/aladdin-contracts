pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/Address.sol";
import "../common/SafeERC20.sol";

contract DAOFunding {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;
    address public rewardDistributor;

    IERC20 public want;
    IERC20 public reward;
    uint public rate; // wants per share
    uint public shareCap;

    mapping(address => bool) public isWhitelisted;
    address[] public whitelist;

    mapping(address => uint) public shares;
    uint public totalShares;

    uint public rewardsPerShareStored;
    mapping(address => uint256) public rewardsPerSharePaid;
    mapping(address => uint256) public rewards;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _want,
        address _reward,
        uint _rate,
        uint _shareCap,
        address[] memory _whitelist
    )
        public
    {
        want = IERC20(_want);
        reward = IERC20(_reward);
        rate = _rate;
        shareCap = _shareCap;
        whitelist = _whitelist;

        for (uint i=0; i<_whitelist.length - 1; i++) {
            isWhitelisted[_whitelist[i]] = true;
        }

        governance = msg.sender;
        rewardDistributor = msg.sender;
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance);
        _;
    }

    modifier onlyDistributor() {
        require(msg.sender == rewardDistributor);
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // fund the dao and get shares
    function fund(uint _shares) external {
        require(shares[msg.sender].add(_shares) <= shareCap, "!over cap");

        uint w = _shares.mul(rate);
        want.safeTransferFrom(msg.sender, address(this), w);

        shares[msg.sender] = shares[msg.sender].add(_shares);
        totalShares = totalShares.add(_shares);
    }

    // claim dao rewards based on shares
    function claim() external {
        rewards[msg.sender] = earned(msg.sender);
        rewardsPerSharePaid[msg.sender] = rewardsPerShareStored;

        uint r = rewards[msg.sender];
        if (r > 0) {
            rewards[msg.sender] = 0;
            reward.safeTransfer(msg.sender, r);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function holdings(address _token)
        public
        view
        returns (uint)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    function earned(address _account) public view returns (uint) {
        return shares[_account].mul(rewardsPerShareStored.sub(rewardsPerSharePaid[_account])).div(1e18).add(rewards[_account]);
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

    function notifyRewardAmount(uint _amount) public onlyDistributor {
        rewardsPerShareStored = rewardsPerShareStored.add(_amount.div(totalShares));
    }

    function setGov(address _governance)
        public
        onlyGov
    {
        governance = _governance;
    }

    function setDistributor(address _rewardDistributor)
        public
        onlyGov
    {
        rewardDistributor = _rewardDistributor;
    }

    function setWant(address _want)
        public
        onlyGov
    {
        want = IERC20(_want);
    }

    function setReward(address _reward)
        public
        onlyGov
    {
        reward = IERC20(_reward);
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
