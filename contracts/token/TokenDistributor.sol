pragma solidity 0.6.12;

import "../common/IERC20.sol";
import "../common/SafeERC20.sol";

// A simple token distributor that takes any ERC20 token, and allows Fund Manager roles to transfer token to recipients.
contract TokenDistributor {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public governance;
    mapping(address => bool) public fundManager;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address[] memory _fundManagers
    )
        public
    {
        governance = msg.sender;

        for(uint256 i = 0; i < _fundManagers.length; i++) {
            fundManager[_fundManagers[i]] = true;
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addFundManager(address _address)
        external
        onlyGov
    {
        fundManager[_address] = true;
    }

    function removeFundManager(address _address)
        external
        onlyGov
    {
        fundManager[_address] = false;
    }

    // Allow governance to rescue rewards
    function rescue(address _rewardToken)
        public
        onlyGov
    {
        uint _balance = IERC20(_rewardToken).balanceOf(address(this));
        IERC20(_rewardToken).safeTransfer(governance, _balance);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function distributeTokens(
        address[] calldata _recipients,
        IERC20[] calldata _tokens,
        uint256[] calldata _amounts
    )
        external
        onlyFundManager
    {
        uint256 len = _recipients.length;
        require(len > 0, "Must choose recipients");
        require(len == _tokens.length, "Mismatching inputs");
        require(len == _amounts.length, "Mismatching inputs");

        for(uint i = 0; i < len; i++){
            uint256 amount = _amounts[i];
            IERC20 rewardToken = _tokens[i];
            address recipient = _recipients[i];
            // Send the RewardToken to recipient
            rewardToken.safeTransfer(recipient, amount);

            emit DistributedToken(msg.sender, recipient, address(rewardToken), amount);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyFundManager() {
        require(fundManager[msg.sender] == true, "!manager");
        _;
    }

    /* ========== EVENTS ========== */

    event DistributedToken(address funder, address recipient, address rewardToken, uint256 amount);
}
