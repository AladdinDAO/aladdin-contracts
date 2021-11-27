// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IStaking.sol";
import "../interfaces/ITreasury.sol";

// TODO: add events

contract AssetBondDepositor is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // The address of Treasury.
  address public immutable treasury;

  // The address of Staking.
  address public immutable staking;

  // Record whether an asset can be used to bond ALD.
  mapping(address => bool) isBondAsset;
  // Record whether an asset is liquidity token.
  mapping(address => bool) isLiquidityToken;

  constructor(
    address _ald,
    address _treasury,
    address _staking
  ) {
    treasury = _treasury;
    staking = _staking;

    IERC20(_ald).safeApprove(_staking, uint256(-1));
  }

  /********************************** View Functions **********************************/

  function getBondALD(address _token, uint256 _amount) external view returns (uint256) {
    if (!isBondAsset[_token]) return 0;

    uint256 _value = ITreasury(treasury).valueOf(_token, _amount);
    return ITreasury(treasury).bondOf(_token, _value);
  }

  /********************************** Mutated Functions **********************************/

  function deposit(address _token, uint256 _amount) external nonReentrant {
    require(isBondAsset[_token], "AssetBondDepositor: not approved");

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 _bondAmount;
    if (isLiquidityToken[_token]) {
      _bondAmount = ITreasury(treasury).deposit(ITreasury.ReserveType.LIQUIDITY_TOKEN, _token, _amount);
    } else {
      _bondAmount = ITreasury(treasury).deposit(ITreasury.ReserveType.UNDERLYING, _token, _amount);
    }

    IStaking(staking).bondFor(msg.sender, _bondAmount);
  }

  /********************************** Restricted Functions **********************************/

  function updateBondAsset(address _token, bool _status) external onlyOwner {
    isBondAsset[_token] = _status;
    if (_status) {
      IERC20(_token).safeApprove(treasury, uint256(-1));
    } else {
      IERC20(_token).safeApprove(treasury, 0);
    }
  }

  function addLiquidityToken(address _token) external onlyOwner {
    isBondAsset[_token] = true;
    isLiquidityToken[_token] = true;

    IERC20(_token).safeApprove(treasury, uint256(-1));
  }
}
