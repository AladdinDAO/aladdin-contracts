// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IStaking.sol";
import "../interfaces/IXALD.sol";
import "../interfaces/IWXALD.sol";

contract Staking is Ownable, IStaking {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct LockedBalance {
    uint192 amount;
    uint32 lockedEpoch;
    uint32 unlockEpoch;
  }

  struct BondBalance {
    uint192 amount;
    uint32 lockedEpoch;
    uint32 unlockEpoch;
  }

  // The address of ALD token.
  address public immutable ALD;
  // The address of xALD token.
  address public immutable xALD;
  // The address of wxALD token.
  address public immutable wxALD;

  // Whether staking is paused.
  bool public paused;

  // Whether to enable whitelist mode.
  bool public enableWhitelist;
  mapping(address => bool) public isWhitelist;

  // The default locking period in epoch.
  uint256 public defaultLockingPeriod;

  // Mapping from user address to locking period in epoch.
  mapping(address => uint32) public lockingPeriod;

  // Mapping from user address to staked ald balances.
  mapping(address => LockedBalance[]) private userLocks;

  // The address of direct bond contract.
  address public assetBondDepositor;
  // Mapping from user address to direct bond ald balances.
  mapping(address => LockedBalance[]) private assetBondLocks;

  // The address of vault reward bond contract.
  address public immutable rewardBondDepositor;
  // Mapping from epoch to token address to reward bond ald balance.
  mapping(uint32 => mapping(address => BondBalance)) private rewardBondLocks;

  // Mapping from user address to lastest interacted epoch number.
  mapping(address => uint32) private checkpoint;

  constructor(
    address _ALD,
    address _xALD,
    address _wxALD,
    address _rewardBondDepositor
  ) {
    ALD = _ALD;
    xALD = _xALD;
    wxALD = _wxALD;

    paused = true;
    enableWhitelist = true;

    defaultLockingPeriod = 90;

    rewardBondDepositor = _rewardBondDepositor;
  }

  /********************************** View Functions **********************************/

  function pendingALD(address _account) external view returns (uint256) {
  }

  function unlockedALD(address _account) external view returns (uint256) {
  }

  /********************************** Mutated Functions **********************************/

  function stake(uint256 _amount) external override {
    IERC20(ALD).safeTransferFrom(msg.sender, address(this), _amount);
    _stakeFor(msg.sender, _amount);
  }

  function stakeFor(address _recipient, uint256 _amount) external override {
    IERC20(ALD).safeTransferFrom(msg.sender, address(this), _amount);
    _stakeFor(_recipient, _amount);
  }

  function unstake(address _recipient, uint256 _amount) external override {
    _unstake(_recipient, _amount);
  }

  function unstakeAll(address _recipient) external override {
    uint256 _amount = IXALD(xALD).balanceOf(msg.sender);
    _unstake(_recipient, _amount);
  }

  function bondFor(address _recipient, uint256 _amount) external override {
    require(assetBondDepositor == msg.sender, "Staking: not approved");
    IERC20(ALD).safeTransferFrom(msg.sender, address(this), _amount);
    IXALD(xALD).stake(address(this), _amount);
    _amount = IWXALD(wxALD).wrap(_amount);

    // TODO: bond logic
  }

  function rewardBond(uint256 _epoch, address[] memory _tokens, uint256[] memory _amounts) external override {
    require(rewardBondDepositor == msg.sender, "Staking: not approved");

    // TODO: bond logic
  }

  function redeem(address _recipient, bool _withdraw) external override {
    // TODO: redeem logic
  }

  /********************************** Restricted Functions **********************************/

  /********************************** Internal Functions **********************************/

  function _stakeFor(address _recipient, uint256 _amount) internal {
    IXALD(xALD).stake(address(this), _amount);
    _amount = IWXALD(wxALD).wrap(_amount);
  }

  function _unstake(address _recipient, uint256 _amount) internal {
    IXALD(xALD).unstake(msg.sender, _amount);
    IERC20(ALD).safeTransfer(_recipient, _amount);
  }
}
