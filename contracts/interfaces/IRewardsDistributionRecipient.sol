pragma solidity 0.6.12;

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(address _rewardToken, uint256 reward) external;
}
