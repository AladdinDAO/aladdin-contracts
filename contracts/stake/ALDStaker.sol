// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "../common/IERC20.sol";
import "../common/ERC20.sol";
import "../common/SafeMath.sol";

import "../interfaces/ITokenMaster.sol";

// Staker for ALD that auto compound farmed yields from TokenMaster
// Forked from the original SushiBar https://github.com/sushiswap/sushiswap/blob/canary/contracts/SushiBar.sol
// Changes:
// 1. Name changes
// 2. Add hook for TokenMaster

contract ALDStaker is ERC20("Staked ALD", "xALD"){
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC20 public ald;
    IERC20 public stakingTokenWrappper;
    ITokenMaster public tokenMaster;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20 _ald,
        ITokenMaster _tokenMaster
    ) public {
        ald = _ald;
        tokenMaster = _tokenMaster;
    }

    function init(IERC20 _stakingTokenWrapper) external {
        require(address(stakingTokenWrappper) == address(0), "already init");
        stakingTokenWrappper = _stakingTokenWrapper;
    }

    /* ========== VIEWS ========== */

    // Total ALD = ALD locked + pendingALD
    function totalALDBalance() external returns (uint) {
        ald.balanceOf(address(this)).add(tokenMaster.pendingALD(address(stakingTokenWrappper), address(this)));
    }

    /* ========== MUTATIVES ========== */

    // Pay some ALDs. Earn some shares.
    // Locks ALD and mints xALD
    function enter(uint256 _amount) external {
        harvest();

        // Gets the amount of ALD locked in the contract
        uint256 totalALD = ald.balanceOf(address(this));
        // Gets the amount of xALD in existence
        uint256 totalShares = totalSupply();
        // If no xALD exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalALD == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xALD the ALD is worth. The ratio will change overtime, as xALD is burned/minted and ALD deposited + gained from rewards / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalALD);
            _mint(msg.sender, what);
        }
        // Lock the ALD in the contract
        ald.transferFrom(msg.sender, address(this), _amount);

        emit Enter(msg.sender, _amount);
    }

    // Withdraw your ALDs.
    // Unlocks the staked + gained ALD and burns xALD
    function leave(uint256 _share) external {
        harvest();

        // Gets the amount of xALD in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of ALD the xALD is worth
        uint256 what = _share.mul(ald.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        ald.transfer(msg.sender, what);

        emit Leave(msg.sender, what);
    }

    // Claim farmed ALDs from TokenMaster
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
