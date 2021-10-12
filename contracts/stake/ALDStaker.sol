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
// 2. Add hook for TokenMaster claim

contract ALDStaker is ERC20("Staked ALD", "xALD"){
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC20 public ald;
    address public rewardDummy;
    ITokenMaster public tokenMaster;

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20 _ald, ITokenMaster _tokenMaster, address _rewardDummy) public {
        ald = _ald;
        tokenMaster = _tokenMaster;
        rewardDummy = _rewardDummy;
    }

    /* ========== VIEWS ========== */

    // Total ALD = ALD locked + pendingALD
    function totalALD() external returns (uint) {
        ald.balanceOf(address(this)).add(tokenMaster.pendingALD(rewardDummy, address(this)));
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
        // Calculate and mint the amount of xALD the ALD is worth. The ratio will change overtime, as xALD is burned/minted and ALD deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalALD);
            _mint(msg.sender, what);
        }
        // Lock the ALD in the contract
        ald.transferFrom(msg.sender, address(this), _amount);
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
    }

    // Claim farmed ALDs from TokenMaster
    function harvest() public {
        tokenMaster.deposit(rewardDummy, 0);
    }
}
