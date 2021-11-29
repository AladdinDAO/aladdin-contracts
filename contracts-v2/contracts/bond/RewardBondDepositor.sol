// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IVault.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IRewardBondDepositor.sol";

contract RewardBondDepositor is Ownable, IRewardBondDepositor {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 private constant MAX_REWARD_TOKENS = 4;

  struct Epoch {
    uint64 epochNumber;
    uint64 startBlock;
    uint64 nextBlock;
    uint64 epochLength;
  }

  struct AccountCheckpoint {
    uint32 epochNumber;
    uint32 blockNumber;
    uint192 rewardShare;
  }

  struct AccountEpochShare {
    uint32 startEpoch; // include
    uint32 endEpoch; // not inclued
    uint192 totalShare;
  }

  struct PendingBondReward {
    bool hasReward;
    uint256[MAX_REWARD_TOKENS] amounts;
  }

  // The address of ald.
  address public immutable ald;
  // The address of Treasury.
  address public immutable treasury;

  // The address of staking contract
  address public staking;

  // The struct of current epoch.
  Epoch public override currentEpoch;

  // A list of epoch infomation.
  // 65536 epoch is about 170 years.
  Epoch[65536] public epoches;

  // A list of vaults. Push only, beware false-positives.
  address[] public vaults;
  // Record whether an address is vault or not.
  mapping(address => bool) public isVault;
  // Mapping from vault address to a list of reward tokens.
  mapping(address => address[]) public rewardTokens;

  // Mapping from vault address to token address to reward amount in current epoch.
  mapping(address => PendingBondReward) public rewards;
  // Mapping from epoch number to vault address to total reward share.
  mapping(uint256 => mapping(address => uint256)) public override rewardShares;

  // The address of keeper.
  address public keeper;

  // Mapping from vault address to global checkpoint block
  mapping(address => uint256) private checkpointBlock;

  // Mapping from user address to vault address to account checkpoint.
  mapping(address => mapping(address => AccountCheckpoint)) private accountCheckpoint;

  // Mapping from user address to vault address to account epoch shares.
  mapping(address => mapping(address => AccountEpochShare[])) private accountEpochShares;

  // Mapping from user address to a list of interacted vault
  mapping(address => address[]) private accountVaults;

  address private _initializer;

  constructor(
    address _ald,
    address _treasury,
    uint64 _epochLength
  ) {
    require(_ald != address(0), "RewardBondDepositor: not zero address");
    require(_treasury != address(0), "RewardBondDepositor: not zero address");
    ald = _ald;
    treasury = _treasury;

    currentEpoch = Epoch({
      epochNumber: 0,
      startBlock: uint64(block.number),
      nextBlock: uint64(block.number + _epochLength),
      epochLength: uint64(_epochLength)
    });

    _initializer = msg.sender;
  }

  function initialize(address _staking) external {
    require(_initializer == msg.sender, "RewardBondDepositor: only initializer");
    require(_staking != address(0), "RewardBondDepositor: not zero address");

    IERC20(ald).safeApprove(_staking, uint256(-1));
    staking = _staking;

    _initializer = address(0);
  }

  /********************************** View Functions **********************************/

  function getVaultsFromAccount(address _user) external view override returns (address[] memory) {
    return accountVaults[_user];
  }

  function getCurrentEpochRewardShare(address _vault) external view returns (uint256) {
    uint256 _share = rewardShares[currentEpoch.epochNumber][_vault];
    uint256 _balance = IVault(_vault).balance();
    uint256 _lastBlock = checkpointBlock[_vault];
    return _share.add(_balance.mul(block.number - _lastBlock));
  }

  function getCurrentEpochAccountRewardShare(address _user, address _vault) external view returns (uint256) {
    AccountCheckpoint memory _accountCheckpoint = accountCheckpoint[_user][_vault];
    if (_accountCheckpoint.blockNumber == 0) return 0;

    Epoch memory _epoch = currentEpoch;
    uint256 _balance = IVault(_vault).balanceOf(_user);

    if (_accountCheckpoint.epochNumber == _epoch.epochNumber) {
      return _balance.mul(block.number - _accountCheckpoint.blockNumber).add(_accountCheckpoint.rewardShare);
    } else {
      return _balance.mul(block.number - currentEpoch.startBlock);
    }
  }

  function getAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault
  ) external view override returns (uint256[] memory) {
    uint256[] memory _shares = new uint256[](currentEpoch.epochNumber - _epoch);
    if (_shares.length == 0) return _shares;

    // it is a new user. all shares equals to zero
    if (accountCheckpoint[_user][_vault].blockNumber == 0) return _shares;

    _getRecordedAccountRewardShareSince(_epoch, _user, _vault, _shares);
    _getPendingAccountRewardShareSince(_epoch, _user, _vault, _shares);

    return _shares;
  }

  /********************************** Mutated Functions **********************************/

  function notifyRewards(address _user, uint256[] memory _amounts) external override {
    require(isVault[msg.sender], "RewardBondDepositor: not approved");

    _checkpoint(msg.sender);
    _userCheckpoint(_user, msg.sender);

    PendingBondReward storage _pending = rewards[msg.sender];
    bool hasReward = false;

    address[] memory _tokens = rewardTokens[msg.sender];
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _pool = IERC20(_tokens[i]).balanceOf(address(this));
      IERC20(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
      uint256 _amount = IERC20(_tokens[i]).balanceOf(address(this)).sub(_pool);
      if (_amount > 0) {
        hasReward = true;
      }
      _pending.amounts[i] = _pending.amounts[i].add(_amount);
    }

    if (hasReward && !_pending.hasReward) {
      _pending.hasReward = true;
    }
  }

  function bond(address _vault) external override {
    require(msg.sender == keeper, "RewardBondDepositor: not keeper");

    _bond(_vault);
  }

  function rebase() external override {
    require(msg.sender == keeper, "RewardBondDepositor: not keeper");

    Epoch memory _currentEpoch = currentEpoch;
    require(block.number >= currentEpoch.nextBlock, "RewardBondDepositor: too soon");

    // bond for vault has pending rewards
    uint256 length = vaults.length;
    for (uint256 i = 0; i < length; i++) {
      address _vault = vaults[i];
      _checkpoint(_vault);
      _bond(_vault);
    }

    IStaking(staking).rebase();

    // record passed epoch info
    epoches[_currentEpoch.epochNumber] = Epoch({
      epochNumber: _currentEpoch.epochNumber,
      startBlock: _currentEpoch.startBlock,
      nextBlock: uint64(block.number),
      epochLength: uint64(block.number - _currentEpoch.startBlock)
    });

    // update current epoch info
    currentEpoch = Epoch({
      epochNumber: _currentEpoch.epochNumber + 1,
      startBlock: uint64(block.number),
      nextBlock: uint64(block.number + _currentEpoch.epochLength),
      epochLength: _currentEpoch.epochLength
    });
  }

  /********************************** Restricted Functions **********************************/

  function updateKeeper(address _keeper) external onlyOwner {
    keeper = _keeper;
  }

  function updateVault(address _vault, bool status) external onlyOwner {
    if (status) {
      require(!isVault[_vault], "RewardBondDepositor: already added");
      isVault[_vault] = true;
      if (!_listContainsAddress(vaults, _vault)) {
        vaults.push(_vault);

        address[] memory _rewardTokens = IVault(_vault).getRewardTokens();
        require(_rewardTokens.length <= MAX_REWARD_TOKENS, "RewardBondDepositor: too much reward");
        // approve token for treasury
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
          IERC20(_rewardTokens[i]).safeApprove(treasury, uint256(-1));
        }

        rewardTokens[_vault] = _rewardTokens;
      }
    } else {
      require(isVault[_vault], "RewardBondDepositor: already removed");
      isVault[_vault] = false;
    }
  }

  /********************************** Internal Functions **********************************/

  function _bond(address _vault) internal {
    require(isVault[_vault], "RewardBondDepositor: vault not approved");

    PendingBondReward storage _pending = rewards[_vault];
    if (!_pending.hasReward) return;

    address[] memory _tokens = rewardTokens[_vault];
    address _treasury = treasury;
    uint256 _bondAmount = 0;
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _amount = ITreasury(_treasury).deposit(
        ITreasury.ReserveType.VAULT_REWARD,
        _tokens[i],
        _pending.amounts[i]
      );
      _bondAmount = _bondAmount.add(_amount);
    }

    IStaking(staking).rewardBond(_vault, _bondAmount);

    delete rewards[_vault];
  }

  function _checkpoint(address _vault) internal {
    uint256 _lastBlock = checkpointBlock[_vault];
    if (_lastBlock > 0 && _lastBlock < block.number) {
      uint256 _share = rewardShares[currentEpoch.epochNumber][_vault];
      uint256 _balance = IVault(_vault).balance();
      rewardShares[currentEpoch.epochNumber][_vault] = _share.add(_balance.mul(block.number - _lastBlock));
    }
    checkpointBlock[_vault] = block.number;
  }

  function _userCheckpoint(address _user, address _vault) internal {
    AccountCheckpoint memory _accountCheckpoint = accountCheckpoint[_user][_vault];

    // updated in current block.
    if (block.number == _accountCheckpoint.blockNumber) {
      return;
    }

    // keep track the vaults which user interacted with.
    if (!_listContainsAddress(accountVaults[_user], _vault)) {
      accountVaults[_user].push(_vault);
    }

    // it's a new user, just record the checkpoint
    if (_accountCheckpoint.blockNumber == 0) {
      accountCheckpoint[_user][_vault] = AccountCheckpoint({
        epochNumber: uint32(currentEpoch.epochNumber),
        blockNumber: uint32(block.number),
        rewardShare: 0
      });
      return;
    }

    Epoch memory _cur = currentEpoch;
    uint256 _balance = IVault(_vault).balanceOf(_user);

    if (_accountCheckpoint.epochNumber == _cur.epochNumber) {
      // In the same epoch
      uint256 newShare = uint256(_accountCheckpoint.rewardShare).add(
        _balance.mul(block.number - _accountCheckpoint.blockNumber)
      );
      accountCheckpoint[_user][_vault] = AccountCheckpoint({
        epochNumber: uint32(currentEpoch.epochNumber),
        blockNumber: uint32(block.number),
        rewardShare: uint192(newShare)
      });
    } else {
      // across multiple epoches
      AccountEpochShare[] storage _shareList = accountEpochShares[_user][_vault];

      Epoch memory _next;
      if (_accountCheckpoint.epochNumber + 1 == _cur.epochNumber) {
        _next = _cur;
      } else {
        _next = epoches[_accountCheckpoint.epochNumber + 1];
      }

      uint256 newShare = uint256(_accountCheckpoint.rewardShare).add(
        _balance.mul(_next.startBlock - _accountCheckpoint.blockNumber)
      );

      // push current checkpoint to list
      _shareList.push(
        AccountEpochShare({
          startEpoch: _accountCheckpoint.epochNumber,
          endEpoch: _accountCheckpoint.epochNumber + 1,
          totalShare: uint192(newShare)
        })
      );

      // push old epoches to list
      if (_next.epochNumber < _cur.epochNumber) {
        _shareList.push(
          AccountEpochShare({
            startEpoch: uint32(_next.epochNumber),
            endEpoch: uint32(_cur.epochNumber),
            totalShare: uint192(_balance.mul(_cur.startBlock - _next.startBlock))
          })
        );
      }

      // update account checkpoint to latest one
      accountCheckpoint[_user][_vault] = AccountCheckpoint({
        epochNumber: uint32(_cur.epochNumber),
        blockNumber: uint32(block.number),
        rewardShare: uint192(_balance.mul(block.number - _cur.startBlock))
      });
    }
  }

  function _listContainsAddress(address[] storage _list, address _item) internal view returns (bool) {
    uint256 length = _list.length;
    for (uint256 i = 0; i < length; i++) {
      if (_list[i] == _item) return true;
    }
    return false;
  }

  function _getRecordedAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault,
    uint256[] memory _shares
  ) internal view {
    AccountEpochShare[] storage _accountEpochShares = accountEpochShares[_user][_vault];
    uint256 length = _accountEpochShares.length;

    Epoch memory _cur = currentEpoch;
    Epoch memory _now = epoches[0];
    Epoch memory _next;
    for (uint256 i = 0; i < length; i++) {
      AccountEpochShare memory _epochShare = _accountEpochShares[i];
      if (_epochShare.endEpoch == _cur.epochNumber) {
        _next = _cur;
      } else {
        _next = epoches[_epochShare.endEpoch];
      }
      uint256 blocks = _next.startBlock - _now.startBlock;
      uint256 _start;
      if (_epoch <= _epochShare.startEpoch) {
        _start = _epochShare.startEpoch;
      } else if (_epoch < _epochShare.endEpoch) {
        _start = _epoch;
      } else {
        _start = _epochShare.endEpoch;
      }
      _now = _next;

      for (uint256 j = _start; j < _epochShare.endEpoch; j++) {
        if (_epochShare.endEpoch == _epochShare.startEpoch + 1) {
          _shares[j - _epoch] = _epochShare.totalShare;
        } else {
          if (_epochShare.endEpoch == _cur.epochNumber) {
            _next = _cur;
          } else {
            _next = epoches[j];
          }
          _shares[j - _epoch] = uint256(_epochShare.totalShare).mul(_next.epochLength).div(blocks);
        }
      }
    }
  }

  function _getPendingAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault,
    uint256[] memory _shares
  ) internal view {
    Epoch memory _cur = currentEpoch;
    AccountCheckpoint memory _accountCheckpoint = accountCheckpoint[_user][_vault];
    if (_accountCheckpoint.epochNumber == _cur.epochNumber) return;

    uint256 _balance = IVault(_vault).balanceOf(_user);

    if (_accountCheckpoint.epochNumber >= _epoch) {
      Epoch memory _next;
      if (_accountCheckpoint.epochNumber + 1 == _cur.epochNumber) {
        _next = _cur;
      } else {
        _next = epoches[_accountCheckpoint.epochNumber + 1];
      }
      _shares[_accountCheckpoint.epochNumber - _epoch] = uint256(_accountCheckpoint.rewardShare).add(
        _balance.mul(_next.startBlock - _accountCheckpoint.blockNumber)
      );
    }

    for (uint256 i = _accountCheckpoint.epochNumber + 1; i < _cur.epochNumber; i++) {
      if (i >= _epoch) {
        _shares[i - _epoch] = _balance.mul(epoches[i].epochLength);
      }
    }
  }
}
