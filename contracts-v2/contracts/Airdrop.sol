// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IXALD.sol";
import "./interfaces/IWXALD.sol";
import "./interfaces/IStaking.sol";

contract Airdrop {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// The address of ALD token.
  address public immutable ald;
  /// The address of xALD token.
  address public immutable xald;
  /// The address of wxALD token.
  address public immutable wxald;
  /// The address of staking contract.
  address public immutable staking;

  /// Mapping from user address to wxALD amount.
  mapping(address => uint256) public shares;

  /// @param _ald The address of ALD token.
  /// @param _xald The address of xALD token.
  /// @param _wxald The address of wxALD token.
  constructor(
    address _ald,
    address _xald,
    address _wxald,
    address _staking
  ) {
    require(_staking != address(0), "Treasury: zero address");
    require(_ald != address(0), "Treasury: zero address");
    require(_xald != address(0), "Treasury: zero address");
    require(_wxald != address(0), "Treasury: zero address");

    ald = _ald;
    xald = _xald;
    wxald = _wxald;
    staking = _staking;

    IERC20(_xald).safeApprove(_wxald, uint256(-1));
    IERC20(_ald).safeApprove(_staking, uint256(-1));
  }

  /// @dev return the pending claimable XALD token for given user.
  /// @param _user The address of user.
  function pendingXALD(address _user) external view returns (uint256) {
    uint256 _share = shares[_user];
    return IWXALD(wxald).wrappedXALDToXALD(_share);
  }

  function claim() external {
    uint256 _share = shares[msg.sender];
    uint256 _amount = IWXALD(wxald).unwrap(_share);
    shares[msg.sender] = 0;

    IERC20(xald).safeTransfer(msg.sender, _amount);
  }

  /// @dev Airdop XALD to a list of users.
  function distributeXALD(address[] memory _users, uint256[] memory _amounts) external {
    require(_users.length == _amounts.length, "Airdrop: length mismatch");

    uint256 _totalAmount;
    for (uint256 i = 0; i < _amounts.length; i++) {
      _totalAmount = _totalAmount.add(_amounts[i]);
    }

    IERC20(xald).safeTransferFrom(msg.sender, address(this), _totalAmount);
    uint256 _totalShare = IWXALD(wxald).wrap(_totalAmount);

    for (uint256 i = 0; i < _amounts.length; i++) {
      uint256 _share = _amounts[i].mul(_totalShare).div(_totalAmount);
      shares[_users[i]] = shares[_users[i]].add(_share);
    }
  }

  /// @dev Airdop ALD to a list of users. It will stake ALD as XALD for user.
  function distributeALD(address[] memory _users, uint256[] memory _amounts) external {
    require(_users.length == _amounts.length, "Airdrop: length mismatch");

    uint256 _totalAmount;
    for (uint256 i = 0; i < _amounts.length; i++) {
      _totalAmount = _totalAmount.add(_amounts[i]);
    }

    IERC20(ald).safeTransferFrom(msg.sender, address(this), _totalAmount);
    IStaking _staking = IStaking(staking);

    for (uint256 i = 0; i < _amounts.length; i++) {
      _staking.stakeFor(_users[i], _amounts[i]);
    }
  }
}
