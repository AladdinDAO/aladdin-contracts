// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IDistributor.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IXALD.sol";
import "../interfaces/IWXALD.sol";
import "../interfaces/IRewardBondDepositor.sol";

contract Staking is Ownable, IStaking {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Bond(address indexed recipient, uint256 aldAmount, uint256 wxALDAmount);
  event RewardBond(address indexed vault, uint256 aldAmount, uint256 wxALDAmount);
  event Stake(address indexed caller, address indexed recipient, uint256 amount);
  event Unstake(address indexed caller, address indexed recipient, uint256 amount);
  event Redeem(address indexed caller, address indexed recipient, uint256 amount);

  struct UserLockedBalance {
    // The amount of wxALD locked.
    uint192 amount;
    // The block number when the lock starts.
    uint32 lockedBlock;
    // The block number when the lock ends.
    uint32 unlockBlock;
  }

  struct RewardBondBalance {
    // The block number when the lock starts.
    uint32 lockedBlock;
    // The block number when the lock ends.
    uint32 unlockBlock;
    // Mapping from vault address to the amount of wxALD locked.
    mapping(address => uint256) amounts;
  }

  struct Checkpoint {
    uint128 epochNumber;
    uint128 blockNumber;
  }

  // The address of ALD token.
  address public immutable ALD;
  // The address of xALD token.
  address public immutable xALD;
  // The address of wxALD token.
  address public immutable wxALD;
  // The address of direct bond contract.
  address public immutable directBondDepositor;
  // The address of vault reward bond contract.
  address public immutable rewardBondDepositor;

  // The address of distributor.
  address public distributor;

  // Whether staking is paused.
  bool public paused;

  // Whether to enable whitelist mode.
  bool public enableWhitelist;
  mapping(address => bool) public isWhitelist;

  // The default locking period in epoch.
  uint256 public defaultLockingPeriod;
  // The bond locking period in epoch.
  uint256 public bondLockingPeriod;
  // Mapping from user address to locking period in epoch.
  mapping(address => uint256) public lockingPeriod;

  // Mapping from user address to staked ald balances.
  mapping(address => UserLockedBalance[]) private userStakedLocks;
  // Mapping from user address to asset bond ald balances.
  mapping(address => UserLockedBalance[]) private userDirectBondLocks;
  // Mapping from user address to reward bond ald balances.
  mapping(address => UserLockedBalance[]) private userRewardBondLocks;

  // The list of reward bond ald locks.
  // 65536 epoch is about 170 year, assuming 1 epoch = 1 day.
  RewardBondBalance[65536] public rewardBondLocks;

  // Mapping from user address to lastest interacted epoch/block number.
  mapping(address => Checkpoint) private checkpoint;

  modifier notPaused() {
    require(!paused, "Staking: paused");
    _;
  }

  /// @param _ALD The address of ALD token.
  /// @param _xALD The address of xALD token.
  /// @param _wxALD The address of wxALD token.
  /// @param _directBondDepositor The address of direct bond contract.
  /// @param _rewardBondDepositor The address of reward bond contract.
  constructor(
    address _ALD,
    address _xALD,
    address _wxALD,
    address _directBondDepositor,
    address _rewardBondDepositor
  ) {
    require(_ALD != address(0), "Treasury: zero address");
    require(_xALD != address(0), "Treasury: zero address");
    require(_wxALD != address(0), "Treasury: zero address");
    require(_directBondDepositor != address(0), "Treasury: zero address");
    require(_rewardBondDepositor != address(0), "Treasury: zero address");

    ALD = _ALD;
    xALD = _xALD;
    wxALD = _wxALD;

    IERC20(_xALD).safeApprove(_wxALD, uint256(-1));

    paused = true;
    enableWhitelist = true;

    defaultLockingPeriod = 90;
    bondLockingPeriod = 5;

    directBondDepositor = _directBondDepositor;
    rewardBondDepositor = _rewardBondDepositor;
  }

  /********************************** View Functions **********************************/

  /// @dev return the pending xALD amount including locked and unlocked.
  /// @param _user The address of user.
  function pendingXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _lastEpoch = checkpoint[_user].epochNumber;
    if (_lastBlock == block.number) return 0;

    (uint256 epochNumber, , , ) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();

    uint256 pendingAmount = _getPendingWithList(userStakedLocks[_user], _lastBlock);
    pendingAmount = pendingAmount.add(_getPendingWithList(userDirectBondLocks[_user], _lastBlock));
    pendingAmount = pendingAmount.add(_getPendingWithList(userRewardBondLocks[_user], _lastBlock));
    pendingAmount = pendingAmount.add(_getPendingRewardBond(_user, epochNumber, _lastEpoch, _lastBlock));

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the unlocked xALD amount.
  /// @param _user The address of user.
  function unlockedXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _lastEpoch = checkpoint[_user].epochNumber;
    if (_lastBlock == block.number) return 0;

    (uint256 epochNumber, , , ) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();

    uint256 unlockedAmount = _getRedeemableWithList(userStakedLocks[_user], _lastBlock);
    unlockedAmount = unlockedAmount.add(_getRedeemableWithList(userDirectBondLocks[_user], _lastBlock));
    unlockedAmount = unlockedAmount.add(_getRedeemableWithList(userRewardBondLocks[_user], _lastBlock));
    unlockedAmount = unlockedAmount.add(_getRedeemableRewardBond(_user, epochNumber, _lastEpoch, _lastBlock));

    return IWXALD(wxALD).wrappedXALDToXALD(unlockedAmount);
  }

  /********************************** Mutated Functions **********************************/

  /// @dev stake all ALD for xALD.
  function stakeAll() external notPaused {
    if (enableWhitelist) {
      require(isWhitelist[msg.sender], "Staking: not whitelist");
    }

    uint256 _amount = IERC20(ALD).balanceOf(msg.sender);
    _amount = _transferAndWrap(msg.sender, _amount);
    _stakeFor(msg.sender, _amount);
  }

  /// @dev stake ALD for xALD.
  /// @param _amount The amount of ALD to stake.
  function stake(uint256 _amount) external override notPaused {
    if (enableWhitelist) {
      require(isWhitelist[msg.sender], "Staking: not whitelist");
    }

    _amount = _transferAndWrap(msg.sender, _amount);
    _stakeFor(msg.sender, _amount);
  }

  /// @dev stake ALD for others.
  /// @param _recipient The address to receipt xALD.
  /// @param _amount The amount of ALD to stake.
  function stakeFor(address _recipient, uint256 _amount) external override notPaused {
    if (enableWhitelist) {
      require(isWhitelist[msg.sender], "Staking: not whitelist");
    }

    _amount = _transferAndWrap(msg.sender, _amount);
    _stakeFor(_recipient, _amount);
  }

  /// @dev unstake xALD to ALD.
  /// @param _recipient The address to receipt ALD.
  /// @param _amount The amount of xALD to unstake.
  function unstake(address _recipient, uint256 _amount) external override notPaused {
    _unstake(_recipient, _amount);
  }

  /// @dev unstake all xALD to ALD.
  /// @param _recipient The address to receipt ALD.
  function unstakeAll(address _recipient) external override notPaused {
    uint256 _amount = IXALD(xALD).balanceOf(msg.sender);
    _unstake(_recipient, _amount);
  }

  /// @dev bond ALD from direct asset. only called by DirectBondDepositor contract.
  /// @notice all bond on the same epoch are grouped at the expected start block of next epoch.
  /// @param _recipient The address to receipt xALD.
  /// @param _amount The amount of ALD to stake.
  function bondFor(address _recipient, uint256 _amount) external override notPaused {
    require(directBondDepositor == msg.sender, "Staking: not approved");
    uint256 _wxALDAmount = _transferAndWrap(msg.sender, _amount);

    // bond lock logic
    (, , uint256 nextBlock, uint256 epochLength) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();
    UserLockedBalance[] storage _locks = userDirectBondLocks[_recipient];
    uint256 length = _locks.length;

    if (length == 0 || _locks[length - 1].lockedBlock != nextBlock) {
      _locks.push(
        UserLockedBalance({
          amount: uint192(_wxALDAmount),
          lockedBlock: uint32(nextBlock),
          unlockBlock: uint32(nextBlock + epochLength * bondLockingPeriod)
        })
      );
    } else {
      _locks[length - 1].amount = uint192(uint256(_locks[length - 1].amount).add(_wxALDAmount));
    }

    emit Bond(_recipient, _amount, _wxALDAmount);
  }

  /// @dev bond ALD from vault reward. only called by RewardBondDepositor contract.
  /// @notice all bond on the same epoch are grouped at the expected start block of next epoch.
  /// @param _vault The address of vault.
  /// @param _amount The amount of ALD to stake.
  function rewardBond(address _vault, uint256 _amount) external override notPaused {
    require(rewardBondDepositor == msg.sender, "Staking: not approved");
    uint256 _wxALDAmount = _transferAndWrap(msg.sender, _amount);

    (uint256 epochNumber, , uint256 nextBlock, uint256 epochLength) = IRewardBondDepositor(rewardBondDepositor)
      .currentEpoch();
    RewardBondBalance storage _lock = rewardBondLocks[epochNumber];

    if (_lock.lockedBlock == 0) {
      // first bond in current epoch
      _lock.lockedBlock = uint32(nextBlock);
      _lock.unlockBlock = uint32(nextBlock + epochLength * bondLockingPeriod);
    }
    _lock.amounts[_vault] = _lock.amounts[_vault].add(_wxALDAmount);

    emit RewardBond(_vault, _amount, _wxALDAmount);
  }

  /// @dev mint ALD reward for stakers.
  /// @notice assume it is called in `rebase()` from contract `rewardBondDepositor`.
  function rebase() external override notPaused {
    require(rewardBondDepositor == msg.sender, "Staking: not approved");

    if (distributor != address(0)) {
      uint256 _pool = IERC20(ALD).balanceOf(address(this));
      IDistributor(distributor).distribute();
      uint256 _distributed = IERC20(ALD).balanceOf(address(this)).sub(_pool);

      (uint256 epochNumber, , , ) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();
      IXALD(xALD).rebase(epochNumber, _distributed);
    }
  }

  /// @dev redeem unlocked xALD from contract.
  /// @param _recipient The address to receive xALD/ALD.
  /// @param __unstake Whether to unstake xALD to ALD.
  function redeem(address _recipient, bool __unstake) external override notPaused {
    // be carefull when no checkpoint for msg.sender
    uint256 _lastBlock = checkpoint[msg.sender].blockNumber;
    uint256 _lastEpoch = checkpoint[msg.sender].epochNumber;
    if (_lastBlock == block.number) {
      return;
    }

    (uint256 epochNumber, , , ) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();

    uint256 unlockedAmount = _redeemWithList(userStakedLocks[msg.sender], _lastBlock);
    unlockedAmount = unlockedAmount.add(_redeemWithList(userDirectBondLocks[msg.sender], _lastBlock));
    unlockedAmount = unlockedAmount.add(_redeemWithList(userRewardBondLocks[msg.sender], _lastBlock));
    unlockedAmount = unlockedAmount.add(_redeemRewardBondLocks(msg.sender, epochNumber, _lastEpoch, _lastBlock));

    // find the unlocked xALD amount
    unlockedAmount = IWXALD(wxALD).unwrap(unlockedAmount);

    emit Redeem(msg.sender, _recipient, unlockedAmount);

    if (__unstake) {
      IXALD(xALD).unstake(address(this), unlockedAmount);
      IERC20(ALD).safeTransfer(_recipient, unlockedAmount);
      emit Unstake(msg.sender, _recipient, unlockedAmount);
    } else {
      IERC20(xALD).safeTransfer(_recipient, unlockedAmount);
    }

    checkpoint[msg.sender] = Checkpoint({ blockNumber: uint128(block.number), epochNumber: uint128(epochNumber) });
  }

  /********************************** Restricted Functions **********************************/

  function updateDistributor(address _distributor) external onlyOwner {
    distributor = _distributor;
  }

  function updatePaused(bool _paused) external onlyOwner {
    paused = _paused;
  }

  function updateEnableWhitelist(bool _enableWhitelist) external onlyOwner {
    enableWhitelist = _enableWhitelist;
  }

  function updateWhitelist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      isWhitelist[_users[i]] = status;
    }
  }

  function updateBongLockingPeriod(uint256 _bondLockingPeriod) external onlyOwner {
    bondLockingPeriod = _bondLockingPeriod;
  }

  function updateDefaultLockingPeriod(uint256 _defaultLockingPeriod) external onlyOwner {
    defaultLockingPeriod = _defaultLockingPeriod;
  }

  function updateLockingPeriod(address[] memory _users, uint256[] memory _periods) external onlyOwner {
    require(_users.length == _periods.length, "Staking: length mismatch");
    for (uint256 i = 0; i < _users.length; i++) {
      lockingPeriod[_users[i]] = _periods[i];
    }
  }

  /********************************** Internal Functions **********************************/

  /// @dev all stakes on the same epoch are grouped at the expected start block of next epoch.
  /// @param _recipient The address of recipient who receives xALD.
  /// @param _amount The amount of wxALD for the recipient.
  function _stakeFor(address _recipient, uint256 _amount) internal {
    (, , uint256 nextBlock, uint256 epochLength) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();
    UserLockedBalance[] storage _locks = userStakedLocks[_recipient];
    uint256 length = _locks.length;

    // stake lock logic
    if (length == 0 || _locks[length - 1].lockedBlock != nextBlock) {
      uint256 _period = _lockingPeriod(_recipient);

      _locks.push(
        UserLockedBalance({
          amount: uint192(_amount),
          lockedBlock: uint32(nextBlock),
          unlockBlock: uint32(nextBlock + epochLength * _period)
        })
      );
    } else {
      _locks[length - 1].amount = uint192(uint256(_locks[length - 1].amount).add(_amount));
    }

    emit Stake(msg.sender, _recipient, _amount);
  }

  function _unstake(address _recipient, uint256 _amount) internal {
    IXALD(xALD).unstake(msg.sender, _amount);
    IERC20(ALD).safeTransfer(_recipient, _amount);

    emit Unstake(msg.sender, _recipient, _amount);
  }

  function _lockingPeriod(address _user) internal view returns (uint256) {
    uint256 _period = lockingPeriod[_user];
    if (_period == 0) return defaultLockingPeriod;
    else return _period;
  }

  function _transferAndWrap(address _sender, uint256 _amount) internal returns (uint256) {
    IERC20(ALD).safeTransferFrom(_sender, address(this), _amount);
    IXALD(xALD).stake(address(this), _amount);
    return IWXALD(wxALD).wrap(_amount);
  }

  function _redeemRewardBondLocks(
    address _user,
    uint256 _epochNumber,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal returns (uint256) {
    UserLockedBalance[] storage _locks = userRewardBondLocks[_user];
    uint256 unlockedAmount;

    // handle rewardBondLocks
    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);
    for (uint256 i = 0; i < _vaults.length; i++) {
      address _vault = _vaults[i];
      uint256[] memory _shares = IRewardBondDepositor(rewardBondDepositor).getAccountRewardShareSince(
        _lastEpoch,
        _user,
        _vault
      );
      for (uint256 _epoch = _lastEpoch; _epoch < _epochNumber; _epoch++) {
        uint256 _share = _shares[_epoch - _lastEpoch];
        if (_share > 0) {
          uint256 _amount;
          uint256 _lockedBlock;
          uint256 _unlockBlock;
          {
            RewardBondBalance storage _lock = rewardBondLocks[_epoch];
            uint256 _totalShare = IRewardBondDepositor(rewardBondDepositor).rewardShares(_epoch, _vault);
            _amount = _lock.amounts[_vault].mul(_share).div(_totalShare);
            _lockedBlock = _lock.lockedBlock;
            _unlockBlock = _lock.unlockBlock;
          }
          // [_lockedBlock, _unlockBlock), [_lastBlock + 1, block.number + 1)
          uint256 _left = Math.max(_lockedBlock, _lastBlock + 1);
          uint256 _right = Math.min(_unlockBlock, block.number + 1);
          if (_left < _right) {
            unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_unlockBlock - _lockedBlock));
          }
          // some reward unlocked
          if (_unlockBlock > block.number + 1) {
            _locks.push(
              UserLockedBalance({
                amount: uint192(_amount),
                lockedBlock: uint32(_lockedBlock),
                unlockBlock: uint32(_unlockBlock)
              })
            );
          }
        }
      }
    }

    return unlockedAmount;
  }

  function _redeemWithList(UserLockedBalance[] storage _locks, uint256 _lastBlock) internal returns (uint256) {
    uint256 length = _locks.length;
    uint256 unlockedAmount = 0;

    for (uint256 i = 0; i < length; i++) {
      uint256 _amount = _locks[i].amount;
      uint256 _startBlock = _locks[i].lockedBlock;
      uint256 _endBlock = _locks[i].unlockBlock;
      if (_amount > 0 && _startBlock <= block.number) {
        // in this case: _endBlock must greater than _lastBlock
        uint256 _left = Math.max(_lastBlock + 1, _startBlock);
        uint256 _right = Math.min(block.number + 1, _endBlock);
        unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_endBlock - _startBlock));
        if (_endBlock <= block.number) {
          delete _locks[i];
        }
      }
    }

    return unlockedAmount;
  }

  function _getRedeemableWithList(UserLockedBalance[] storage _locks, uint256 _lastBlock)
    internal
    view
    returns (uint256)
  {
    uint256 length = _locks.length;
    uint256 unlockedAmount = 0;

    for (uint256 i = 0; i < length; i++) {
      uint256 _amount = _locks[i].amount;
      uint256 _startBlock = _locks[i].lockedBlock;
      uint256 _endBlock = _locks[i].unlockBlock;
      if (_amount > 0 && _startBlock <= block.number) {
        // in this case: _endBlock must greater than _lastBlock
        uint256 _left = Math.max(_lastBlock + 1, _startBlock);
        uint256 _right = Math.min(block.number + 1, _endBlock);
        unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_endBlock - _startBlock));
      }
    }

    return unlockedAmount;
  }

  function _getPendingWithList(UserLockedBalance[] storage _locks, uint256 _lastBlock) internal view returns (uint256) {
    uint256 length = _locks.length;
    uint256 pendingAmount = 0;

    for (uint256 i = 0; i < length; i++) {
      uint256 _amount = _locks[i].amount;
      uint256 _startBlock = _locks[i].lockedBlock;
      uint256 _endBlock = _locks[i].unlockBlock;
      if (_amount > 0 && _startBlock <= block.number) {
        // in this case: _endBlock must greater than _lastBlock
        uint256 _left = Math.max(_lastBlock + 1, _startBlock);
        pendingAmount = pendingAmount.add(_amount.mul(_endBlock - _left).div(_endBlock - _startBlock));
      }
    }

    return pendingAmount;
  }

  function _getRedeemableRewardBond(
    address _user,
    uint256 _epochNumber,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    uint256 unlockedAmount;
    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);
    for (uint256 i = 0; i < _vaults.length; i++) {
      address _vault = _vaults[i];
      uint256[] memory _shares = IRewardBondDepositor(rewardBondDepositor).getAccountRewardShareSince(
        _lastEpoch,
        _user,
        _vault
      );
      for (uint256 _epoch = _lastEpoch; _epoch < _epochNumber; _epoch++) {
        uint256 _share = _shares[_epoch - _lastEpoch];
        if (_share > 0) {
          uint256 _amount;
          uint256 _lockedBlock;
          uint256 _unlockBlock;
          {
            RewardBondBalance storage _lock = rewardBondLocks[_epoch];
            uint256 _totalShare = IRewardBondDepositor(rewardBondDepositor).rewardShares(_epoch, _vault);
            _amount = _lock.amounts[_vault].mul(_share).div(_totalShare);
            _lockedBlock = _lock.lockedBlock;
            _unlockBlock = _lock.unlockBlock;
          }
          // [_lockedBlock, _unlockBlock), [_lastBlock + 1, block.number + 1)
          uint256 _left = Math.max(_lockedBlock, _lastBlock + 1);
          uint256 _right = Math.min(_unlockBlock, block.number + 1);
          if (_left < _right) {
            unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_unlockBlock - _lockedBlock));
          }
        }
      }
    }

    return unlockedAmount;
  }

  function _getPendingRewardBond(
    address _user,
    uint256 _epochNumber,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    uint256 pendingAmount;
    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);
    for (uint256 i = 0; i < _vaults.length; i++) {
      address _vault = _vaults[i];
      uint256[] memory _shares = IRewardBondDepositor(rewardBondDepositor).getAccountRewardShareSince(
        _lastEpoch,
        _user,
        _vault
      );
      for (uint256 _epoch = _lastEpoch; _epoch < _epochNumber; _epoch++) {
        uint256 _share = _shares[_epoch - _lastEpoch];
        if (_share > 0) {
          uint256 _amount;
          uint256 _lockedBlock;
          uint256 _unlockBlock;
          {
            RewardBondBalance storage _lock = rewardBondLocks[_epoch];
            uint256 _totalShare = IRewardBondDepositor(rewardBondDepositor).rewardShares(_epoch, _vault);
            _amount = _lock.amounts[_vault].mul(_share).div(_totalShare);
            _lockedBlock = _lock.lockedBlock;
            _unlockBlock = _lock.unlockBlock;
          }
          // [_lockedBlock, _unlockBlock), [_lastBlock + 1, oo)
          uint256 _left = Math.max(_lockedBlock, _lastBlock + 1);
          if (_left < _unlockBlock) {
            pendingAmount = pendingAmount.add(_amount.mul(_unlockBlock - _left).div(_unlockBlock - _lockedBlock));
          }
        }
      }
    }

    return pendingAmount;
  }
}
