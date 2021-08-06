pragma solidity 0.6.12;

import "../common/IERC20.sol";
import "../common/SafeERC20.sol";
import "../interfaces/IRewardsDistributionRecipient.sol";

// A simple reward distributor that takes any ERC20 token, and allows anyone to send/notify reward to IRewardsDistributionRecipient based on governance permission.
contract RewardDistributorPermissioned {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /* ========== STATE VARIABLES ========== */

    address public governance;

    mapping(address => bool) public distributableTokens;
    address[] public recipients;
    uint256[] public percentages;

    /* ========== CONSTRUCTOR ========== */

    constructor()
        public
    {
        governance = msg.sender;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setGovernance(address _governance) external onlyGov {
        governance = _governance;
    }

    function allowDistribution(address _token) external onlyGov {
        distributableTokens[_token] = true;
    }

    function disableDistribution(address _token) external onlyGov {
        distributableTokens[_token] = false;
    }

    // Must set recipient and percentages in single tx to avoid discrepency of length
    function setAllocations(
        address[] calldata _recipients,
        uint256[] calldata _percentages
    )
        external
        onlyGov
    {
        require(_recipients.length == _percentages.length, "length does not match");
        uint total = 0;
        for (uint i=0; i<_percentages.length; i++) {
            total = total + _percentages[i];
        }
        require(total == 100, "total percentage is not 100");

        recipients = _recipients;
        percentages = _percentages;
    }

    // Allow governance to rescue rewards
    function rescue(address _rewardToken)
        external
        onlyGov
    {
        uint _balance = IERC20(_rewardToken).balanceOf(address(this));
        IERC20(_rewardToken).safeTransfer(governance, _balance);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function distributeRewards(
        IERC20 _token
    )
        external
    {
        require(distributableTokens[address(_token)] == true, "Not allowed to distribute this token");

        uint total = _token.balanceOf(address(this));
        if (total == 0) {
            return;
        }

        for(uint i = 0; i < recipients.length; i++){
            uint256 amount = total.mul(percentages[i]).div(100);
            address recipient = recipients[i];
            // Send the RewardToken to recipient
            _token.safeTransfer(recipient, amount);
            // Only after successfull tx - notify the contract of the new funds
            IRewardsDistributionRecipient(recipient).notifyRewardAmount(address(_token), amount);

            emit DistributedReward(recipient, address(_token), amount);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    /* ========== EVENTS ========== */

    event DistributedReward(address recipient, address rewardToken, uint256 amount);
}
