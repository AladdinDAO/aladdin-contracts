// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "../common/IERC20.sol";
import "../common/ERC20.sol";
import "../common/SafeMath.sol";

import "../interfaces/ITokenMaster.sol";

// Token staker that auto compound farmed yields
// Forked from the original SushiBar https://github.com/sushiswap/sushiswap/blob/canary/contracts/SushiBar.sol
// Changes:
// 1. Name changes
// 2. Add hook for MasterChef like reward source

contract ALDStaker is ERC20("Staked ALD", "sALD"){
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC20 immutable public stakingToken;
    IERC20 public stakingTokenWrappper;
    ITokenMaster public tokenMaster;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20 _stakingToken,
        ITokenMaster _tokenMaster
    ) public {
        stakingToken = _stakingToken;
        tokenMaster = _tokenMaster;
    }

    function init(IERC20 _stakingTokenWrapper) external {
        require(address(stakingTokenWrappper) == address(0), "already init");
        stakingTokenWrappper = _stakingTokenWrapper;
    }

    /* ========== VIEWS ========== */

    // Total Staked Supply = token staked + reward pending
    function totalStakedBalance() external view returns (uint) {
        return stakingToken.balanceOf(address(this))
                           .add(tokenMaster.pendingALD(address(stakingTokenWrappper), address(this)));
    }

    /* ========== MUTATIVES ========== */

    // Stake token and earn shares
    // Locks staking token and mint shares
    function enter(uint256 _amount) external {
        harvest();

        // Gets the amount of staking token locked in the contract
        uint256 totalAmount = stakingToken.balanceOf(address(this));
        // Gets the amount of shares in existence
        uint256 totalShares = totalSupply();
        // If no shares exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalAmount == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of shares the staking token is worth. The ratio will change overtime, as share is burned/minted and staking token deposited + gained from rewards / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalAmount);
            _mint(msg.sender, what);
        }
        // Lock the token in the contract
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        emit Enter(msg.sender, _amount);
    }

    // Withdraw your staked tokens.
    // Unlocks the staked + gained rewards and burns shares
    function leave(uint256 _share) external {
        harvest();

        // Gets the amount of shares in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of staking token the share is worth
        uint256 what = _share.mul(stakingToken.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        stakingToken.transfer(msg.sender, what);

        emit Leave(msg.sender, what);
    }

    // Claim farmed rewards
    function harvest() public {
        tokenMaster.deposit(address(stakingTokenWrappper), 0);
    }

    // Deposit wrapper token into TokenMaster
    function deposit() external {
        uint amount = stakingTokenWrappper.balanceOf(address(this));
        require(amount > 0, "nothing to be deposited");
        stakingTokenWrappper.approve(address(tokenMaster), amount);
        tokenMaster.deposit(address(stakingTokenWrappper), amount);
    }

    /* ========== EVENTS ========== */

    event Enter(address indexed user, uint256 amount);
    event Leave(address indexed user, uint256 amount);
}
