// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IDistributor.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IXALD.sol";
import "../interfaces/IWXALD.sol";
import "../interfaces/IRewardBondDepositor.sol";

contract Staking is OwnableUpgradeable, IStaking {
  using SafeMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

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

  // The address of governor.
  address public governor;

  // The address of ALD token.
  address public ALD;
  // The address of xALD token.
  address public xALD;
  // The address of wxALD token.
  address public wxALD;
  // The address of direct bond contract.
  address public directBondDepositor;
  // The address of vault reward bond contract.
  address public rewardBondDepositor;

  // The address of distributor.
  address public distributor;

  // Whether staking is paused.
  bool public paused;

  // Whether to enable whitelist mode.
  bool public enableWhitelist;
  mapping(address => bool) public isWhitelist;

  // Whether an address is in black list
  mapping(address => bool) public blacklist;

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

  modifier onlyGovernor() {
    require(msg.sender == governor || msg.sender == owner(), "Treasury: only governor");
    _;
  }

  /// @param _ALD The address of ALD token.
  /// @param _xALD The address of xALD token.
  /// @param _wxALD The address of wxALD token.
  /// @param _rewardBondDepositor The address of reward bond contract.
  function initialize(
    address _ALD,
    address _xALD,
    address _wxALD,
    address _rewardBondDepositor
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    require(_ALD != address(0), "Treasury: zero address");
    require(_xALD != address(0), "Treasury: zero address");
    require(_wxALD != address(0), "Treasury: zero address");
    require(_rewardBondDepositor != address(0), "Treasury: zero address");

    ALD = _ALD;
    xALD = _xALD;
    wxALD = _wxALD;

    IERC20Upgradeable(_xALD).safeApprove(_wxALD, uint256(-1));

    paused = true;
    enableWhitelist = true;

    defaultLockingPeriod = 90;
    bondLockingPeriod = 5;

    rewardBondDepositor = _rewardBondDepositor;
  }

  /********************************** View Functions **********************************/

  /// @dev return the full vested block (staking and bond) for given user
  /// @param _user The address of user;
  function fullyVestedBlock(address _user) external view returns (uint256, uint256) {
    uint256 stakeVestedBlock;
    {
      UserLockedBalance[] storage _locks = userStakedLocks[_user];
      for (uint256 i = 0; i < _locks.length; i++) {
        UserLockedBalance storage _lock = _locks[i];
        if (_lock.amount > 0) {
          stakeVestedBlock = Math.max(stakeVestedBlock, _lock.unlockBlock);
        }
      }
    }
    uint256 bondVestedBlock;
    {
      UserLockedBalance[] storage _locks = userDirectBondLocks[_user];
      for (uint256 i = 0; i < _locks.length; i++) {
        UserLockedBalance storage _lock = _locks[i];
        if (_lock.amount > 0) {
          bondVestedBlock = Math.max(bondVestedBlock, _lock.unlockBlock);
        }
      }
    }
    return (stakeVestedBlock, bondVestedBlock);
  }

  /// @dev return the pending xALD amount including locked and unlocked.
  /// @param _user The address of user.
  function pendingXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _lastEpoch = checkpoint[_user].epochNumber;

    uint256 pendingAmount = _getPendingWithList(userStakedLocks[_user], _lastBlock);
    pendingAmount = pendingAmount.add(_getPendingWithList(userDirectBondLocks[_user], _lastBlock));
    pendingAmount = pendingAmount.add(_getPendingWithList(userRewardBondLocks[_user], _lastBlock));
    pendingAmount = pendingAmount.add(_getPendingRewardBond(_user, _lastEpoch, _lastBlock));

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the pending xALD amount from user staking, including locked and unlocked.
  /// @param _user The address of user.
  function pendingStakedXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;

    uint256 pendingAmount = _getPendingWithList(userStakedLocks[_user], _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the pending xALD amount from user bond, including locked and unlocked.
  /// @param _user The address of user.
  function pendingBondXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;

    uint256 pendingAmount = _getPendingWithList(userDirectBondLocks[_user], _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the pending xALD amount from user vault reward, including locked and unlocked.
  /// @param _user The address of user.
  /// @param _vault The address of vault.
  function pendingXALDByVault(address _user, address _vault) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _startEpoch = _findPossibleStartEpoch(_user, _lastBlock);

    uint256 pendingAmount = _getPendingRewardBondByVault(_user, _vault, _startEpoch, _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the unlocked xALD amount.
  /// @param _user The address of user.
  function unlockedXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _lastEpoch = checkpoint[_user].epochNumber;

    uint256 unlockedAmount = _getRedeemableWithList(userStakedLocks[_user], _lastBlock);
    unlockedAmount = unlockedAmount.add(_getRedeemableWithList(userDirectBondLocks[_user], _lastBlock));
    unlockedAmount = unlockedAmount.add(_getRedeemableWithList(userRewardBondLocks[_user], _lastBlock));
    unlockedAmount = unlockedAmount.add(_getRedeemableRewardBond(_user, _lastEpoch, _lastBlock));

    return IWXALD(wxALD).wrappedXALDToXALD(unlockedAmount);
  }

  /// @dev return the unlocked xALD amount from user staking.
  /// @param _user The address of user.
  function unlockedStakedXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;

    uint256 unlockedAmount = _getRedeemableWithList(userStakedLocks[_user], _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(unlockedAmount);
  }

  /// @dev return the unlocked xALD amount from user bond.
  /// @param _user The address of user.
  function unlockedBondXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;

    uint256 unlockedAmount = _getRedeemableWithList(userDirectBondLocks[_user], _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(unlockedAmount);
  }

  /// @dev return the unlocked xALD amount from user vault reward.
  /// @param _user The address of user.
  /// @param _vault The address of vault.
  function unlockedXALDByVault(address _user, address _vault) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _startEpoch = _findPossibleStartEpoch(_user, _lastBlock);

    uint256 pendingAmount = _getRedeemableRewardBondByVault(_user, _vault, _startEpoch, _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /********************************** Mutated Functions **********************************/

  /// @dev stake all ALD for xALD.
  function stakeAll() external notPaused {
    if (enableWhitelist) {
      require(isWhitelist[msg.sender], "Staking: not whitelist");
    }

    uint256 _amount = IERC20Upgradeable(ALD).balanceOf(msg.sender);
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
      uint256 _pool = IERC20Upgradeable(ALD).balanceOf(address(this));
      IDistributor(distributor).distribute();
      uint256 _distributed = IERC20Upgradeable(ALD).balanceOf(address(this)).sub(_pool);

      (uint256 epochNumber, , , ) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();
      IXALD(xALD).rebase(epochNumber, _distributed);
    }
  }

  /// @dev redeem unlocked xALD from contract.
  /// @param _recipient The address to receive xALD/ALD.
  /// @param __unstake Whether to unstake xALD to ALD.
  function redeem(address _recipient, bool __unstake) external override notPaused {
    require(!blacklist[msg.sender], "Staking: blacklist");

    // be carefull when no checkpoint for msg.sender
    uint256 _lastBlock = checkpoint[msg.sender].blockNumber;
    uint256 _lastEpoch = checkpoint[msg.sender].epochNumber;
    if (_lastBlock == block.number) {
      return;
    }

    uint256 unlockedAmount = _redeemWithList(userStakedLocks[msg.sender], _lastBlock);
    unlockedAmount = unlockedAmount.add(_redeemWithList(userDirectBondLocks[msg.sender], _lastBlock));
    unlockedAmount = unlockedAmount.add(_redeemWithList(userRewardBondLocks[msg.sender], _lastBlock));
    unlockedAmount = unlockedAmount.add(_redeemRewardBondLocks(msg.sender, _lastEpoch, _lastBlock));

    // find the unlocked xALD amount
    unlockedAmount = IWXALD(wxALD).unwrap(unlockedAmount);

    emit Redeem(msg.sender, _recipient, unlockedAmount);

    if (__unstake) {
      IXALD(xALD).unstake(address(this), unlockedAmount);
      IERC20Upgradeable(ALD).safeTransfer(_recipient, unlockedAmount);
      emit Unstake(msg.sender, _recipient, unlockedAmount);
    } else {
      IERC20Upgradeable(xALD).safeTransfer(_recipient, unlockedAmount);
    }

    (uint256 epochNumber, , , ) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();

    checkpoint[msg.sender] = Checkpoint({ blockNumber: uint128(block.number), epochNumber: uint128(epochNumber) });
  }

  /********************************** Restricted Functions **********************************/

  function updateGovernor(address _governor) external onlyOwner {
    governor = _governor;
  }

  function updateDistributor(address _distributor) external onlyOwner {
    distributor = _distributor;
  }

  function updatePaused(bool _paused) external onlyGovernor {
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

  function updateBlacklist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      blacklist[_users[i]] = status;
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

  function updateDirectBondDepositor(address _directBondDepositor) external onlyOwner {
    require(_directBondDepositor != address(0), "Treasury: zero address");

    directBondDepositor = _directBondDepositor;
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
    IERC20Upgradeable(ALD).safeTransfer(_recipient, _amount);

    emit Unstake(msg.sender, _recipient, _amount);
  }

  function _lockingPeriod(address _user) internal view returns (uint256) {
    uint256 _period = lockingPeriod[_user];
    if (_period == 0) return defaultLockingPeriod;
    else return _period;
  }

  function _transferAndWrap(address _sender, uint256 _amount) internal returns (uint256) {
    IERC20Upgradeable(ALD).safeTransferFrom(_sender, address(this), _amount);
    IXALD(xALD).stake(address(this), _amount);
    return IWXALD(wxALD).wrap(_amount);
  }

  function _redeemRewardBondLocks(
    address _user,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal returns (uint256) {
    uint256 unlockedAmount;

    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);
    for (uint256 i = 0; i < _vaults.length; i++) {
      unlockedAmount = unlockedAmount.add(_redeemRewardBondLocksByVault(_user, _vaults[i], _lastEpoch, _lastBlock));
    }

    return unlockedAmount;
  }

  function _redeemRewardBondLocksByVault(
    address _user,
    address _vault,
    uint256 _startEpoch,
    uint256 _lastBlock
  ) internal returns (uint256) {
    IRewardBondDepositor _depositor = IRewardBondDepositor(rewardBondDepositor); // gas saving
    UserLockedBalance[] storage _locks = userRewardBondLocks[_user];
    uint256 unlockedAmount;

    uint256[] memory _shares = _depositor.getAccountRewardShareSince(_startEpoch, _user, _vault);
    for (uint256 i = 0; i < _shares.length; i++) {
      if (_shares[i] == 0) continue;

      uint256 _epoch = _startEpoch + i;
      uint256 _amount = rewardBondLocks[_epoch].amounts[_vault];
      {
        uint256 _totalShare = _depositor.rewardShares(_epoch, _vault);
        _amount = _amount.mul(_shares[i]).div(_totalShare);
      }
      uint256 _lockedBlock = rewardBondLocks[_epoch].lockedBlock;
      uint256 _unlockBlock = rewardBondLocks[_epoch].unlockBlock;

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
    return unlockedAmount;
  }

  function _redeemWithList(UserLockedBalance[] storage _locks, uint256 _lastBlock) internal returns (uint256) {
    uint256 length = _locks.length;
    uint256 unlockedAmount = 0;

    for (uint256 i = 0; i < length; ) {
      uint256 _amount = _locks[i].amount;
      uint256 _startBlock = _locks[i].lockedBlock;
      uint256 _endBlock = _locks[i].unlockBlock;
      if (_amount > 0 && _startBlock <= block.number) {
        // in this case: _endBlock must greater than _lastBlock
        uint256 _left = Math.max(_lastBlock + 1, _startBlock);
        uint256 _right = Math.min(block.number + 1, _endBlock);
        unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_endBlock - _startBlock));
        if (_endBlock <= block.number) {
          // since the order is not important
          // use swap and delete to reduce the length of array
          length -= 1;
          _locks[i] = _locks[length];
          delete _locks[length];
          _locks.pop();
        } else {
          i++;
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
      // [_startBlock, _endBlock), [_lastBlock + 1, oo)
      if (_amount > 0 && _endBlock > _lastBlock + 1) {
        // in this case: _endBlock must greater than _lastBlock
        uint256 _left = Math.max(_lastBlock + 1, _startBlock);
        pendingAmount = pendingAmount.add(_amount.mul(_endBlock - _left).div(_endBlock - _startBlock));
      }
    }

    return pendingAmount;
  }

  function _getRedeemableRewardBond(
    address _user,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    uint256 unlockedAmount;
    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);

    for (uint256 i = 0; i < _vaults.length; i++) {
      unlockedAmount = unlockedAmount.add(_getRedeemableRewardBondByVault(_user, _vaults[i], _lastEpoch, _lastBlock));
    }

    return unlockedAmount;
  }

  function _getPendingRewardBond(
    address _user,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    uint256 pendingAmount;
    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);

    for (uint256 i = 0; i < _vaults.length; i++) {
      pendingAmount = pendingAmount.add(_getPendingRewardBondByVault(_user, _vaults[i], _lastEpoch, _lastBlock));
    }

    return pendingAmount;
  }

  function _getRedeemableRewardBondByVault(
    address _user,
    address _vault,
    uint256 _startEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    IRewardBondDepositor _depositor = IRewardBondDepositor(rewardBondDepositor); // gas saving
    uint256 unlockedAmount;

    uint256[] memory _shares = _depositor.getAccountRewardShareSince(_startEpoch, _user, _vault);
    for (uint256 i = 0; i < _shares.length; i++) {
      if (_shares[i] == 0) continue;

      uint256 _epoch = _startEpoch + i;
      uint256 _unlockBlock = rewardBondLocks[_epoch].unlockBlock;
      if (_unlockBlock <= _lastBlock + 1) continue;

      uint256 _amount = rewardBondLocks[_epoch].amounts[_vault];
      uint256 _lockedBlock = rewardBondLocks[_epoch].lockedBlock;
      {
        uint256 _totalShare = _depositor.rewardShares(_epoch, _vault);
        _amount = _amount.mul(_shares[i]).div(_totalShare);
      }
      // [_lockedBlock, _unlockBlock), [_lastBlock + 1, block.number + 1)
      uint256 _left = Math.max(_lockedBlock, _lastBlock + 1);
      uint256 _right = Math.min(_unlockBlock, block.number + 1);
      if (_left < _right) {
        unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_unlockBlock - _lockedBlock));
      }
    }
    return unlockedAmount;
  }

  function _getPendingRewardBondByVault(
    address _user,
    address _vault,
    uint256 _startEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    IRewardBondDepositor _depositor = IRewardBondDepositor(rewardBondDepositor); // gas saving
    uint256 pendingAmount;

    uint256[] memory _shares = _depositor.getAccountRewardShareSince(_startEpoch, _user, _vault);
    for (uint256 i = 0; i < _shares.length; i++) {
      if (_shares[i] == 0) continue;

      uint256 _epoch = _startEpoch + i;
      uint256 _unlockBlock = rewardBondLocks[_epoch].unlockBlock;
      if (_unlockBlock <= _lastBlock + 1) continue;

      uint256 _amount = rewardBondLocks[_epoch].amounts[_vault];
      uint256 _lockedBlock = rewardBondLocks[_epoch].lockedBlock;
      {
        uint256 _totalShare = _depositor.rewardShares(_epoch, _vault);
        _amount = _amount.mul(_shares[i]).div(_totalShare);
      }
      // [_lockedBlock, _unlockBlock), [_lastBlock + 1, oo)
      uint256 _left = Math.max(_lockedBlock, _lastBlock + 1);
      if (_left < _unlockBlock) {
        pendingAmount = pendingAmount.add(_amount.mul(_unlockBlock - _left).div(_unlockBlock - _lockedBlock));
      }
    }
    return pendingAmount;
  }

  /// @dev Find the possible start epoch for current user to calculate pending/unlocked ALD for vault.
  /// @param _user The address of user.
  /// @param _lastBlock The last block user interacted with the contract.
  function _findPossibleStartEpoch(address _user, uint256 _lastBlock) internal view returns (uint256) {
    uint256 _minLockedBlock = _findEarlistRewardLockedBlock(_user);
    uint256 _lastEpoch = checkpoint[_user].epochNumber;
    if (_minLockedBlock == 0) {
      // No locks available or all locked ALD are redeemed, in this case,
      //  + _lastBlock = 0: user didn't interact with the contract, we should calculate from the first epoch
      //  + _lastBlock != 0: user has interacted with the contract, we should calculate from the last epoch
      if (_lastBlock == 0) return 0;
      else return _lastEpoch;
    } else {
      // Locks available, we should find the epoch number by searching _minLockedBlock
      return _findEpochByLockedBlock(_minLockedBlock, _lastEpoch);
    }
  }

  /// @dev find the epoch whose lockedBlock is `_lockedBlock`.
  /// @param _lockedBlock the epoch to find
  /// @param _epochHint the hint for search the epoch
  function _findEpochByLockedBlock(uint256 _lockedBlock, uint256 _epochHint) internal view returns (uint256) {
    // usually at most `bondLockingPeriod` loop is enough.
    while (_epochHint > 0) {
      if (rewardBondLocks[_epochHint].lockedBlock == _lockedBlock) break;
      _epochHint = _epochHint - 1;
    }
    return _epochHint;
  }

  /// @dev find the earlist reward locked block, which will be used to find possible start epoch
  /// @param _user The address of user.
  function _findEarlistRewardLockedBlock(address _user) internal view returns (uint256) {
    UserLockedBalance[] storage _locks = userRewardBondLocks[_user];
    uint256 length = _locks.length;
    // no locks or all unlocked and redeemed
    if (length == 0) return 0;

    uint256 _minLockedBlock = _locks[0].lockedBlock;
    for (uint256 i = 1; i < length; i++) {
      uint256 _lockedBlock = _locks[i].lockedBlock;
      if (_lockedBlock < _minLockedBlock) {
        _minLockedBlock = _lockedBlock;
      }
    }
    return _minLockedBlock;
  }
}
