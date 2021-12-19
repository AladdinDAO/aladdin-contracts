// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IXALD.sol";
import "./interfaces/IWXALD.sol";
import "./interfaces/IStaking.sol";

contract ALDDaoV2 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Stake(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);

  uint256 public constant PRECISION = 1e18;

  /// The address of xALD token.
  address public immutable xald;
  /// The address of wxALD token.
  address public immutable wxald;
  /// The address of staking.
  address public immutable staking;
  /// The address of DAO token.
  address public immutable dao;

  /// The total ALD DAO token share.
  uint256 public totalShares;
  /// Mapping from user address to ALD DAO share.
  mapping(address => uint256) public shares;

  /// The amount of wxALD per ALD DAO token share.
  uint256 public wxALDPerShare;
  // Mapping from user address to reward per share paid.
  mapping(address => uint256) public wxALDPerSharePaid;
  // Mapping from user address to reward amount.
  mapping(address => uint256) public rewards;

  /// @param _xald The address of xALD token.
  /// @param _wxald The address of wxALD token.
  /// @param _dao The address of DAO token.
  constructor(
    address _xald,
    address _wxald,
    address _staking,
    address _dao
  ) {
    require(_xald != address(0), "Treasury: zero address");
    require(_wxald != address(0), "Treasury: zero address");
    require(_staking != address(0), "Treasury: zero address");
    require(_dao != address(0), "Treasury: zero address");

    xald = _xald;
    wxald = _wxald;
    staking = _staking;
    dao = _dao;

    IERC20(_xald).safeApprove(_wxald, uint256(-1));
  }

  /// @dev return the pending claimable XALD token for given user.
  /// @param _user The address of user.
  function pendingXALD(address _user) public view returns (uint256) {
    uint256 _share = shares[_user];
    return _share.mul(wxALDPerShare.sub(wxALDPerSharePaid[_user])).div(PRECISION).add(rewards[_user]);
  }

  /// @dev stake ALD DAO token.
  /// @param _amount The amount of token to stake.
  function stake(uint256 _amount) external {
    _updateReward(msg.sender);

    totalShares = totalShares.add(_amount);
    shares[msg.sender] = shares[msg.sender].add(_amount);

    IERC20(dao).safeTransferFrom(msg.sender, address(this), _amount);

    emit Stake(msg.sender, _amount);
  }

  /// @dev unstake ALD DAO token.
  /// @param _amount The amount of token to unstake.
  function unstake(uint256 _amount) external {
    _updateReward(msg.sender);

    totalShares = totalShares.sub(_amount);
    shares[msg.sender] = shares[msg.sender].sub(_amount);

    IERC20(dao).safeTransfer(msg.sender, _amount);

    emit Unstake(msg.sender, _amount);
  }

  /// @dev Claim pending xALD/ALD.
  /// @param _unstake whether to unstake xALD to ALD.
  function claim(bool _unstake) external {
    _updateReward(msg.sender);

    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      reward = IWXALD(wxald).unwrap(reward);
      if (_unstake) {
        IStaking(staking).unstake(msg.sender, reward);
      } else {
        IERC20(xald).safeTransfer(msg.sender, reward);
      }
    }

    emit Claim(msg.sender, reward);
  }

  /// @dev redeem xALD reward from staking contract.
  function redeem() external {
    IStaking(staking).redeem(address(this), false);
    uint256 _amount = IWXALD(wxald).wrap(IERC20(xald).balanceOf(address(this)));

    wxALDPerShare = wxALDPerShare.add(_amount.mul(1e18).div(totalShares));
  }

  /// @dev someone may donate xALD to this contract.
  /// @param _amount The amount of xALD to donate.
  function donate(uint256 _amount) external {
    IERC20(xald).safeTransferFrom(msg.sender, address(this), _amount);
    _amount = IWXALD(wxald).wrap(IERC20(xald).balanceOf(address(this)));

    wxALDPerShare = wxALDPerShare.add(_amount.mul(1e18).div(totalShares));
  }

  /// @dev Update pending xALD reward for user.
  /// @param _user The address of account.
  function _updateReward(address _user) internal {
    rewards[_user] = pendingXALD(_user);
    wxALDPerSharePaid[_user] = wxALDPerShare;
  }
}
