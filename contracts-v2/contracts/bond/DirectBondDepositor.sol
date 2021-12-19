// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IStaking.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract DirectBondDepositor is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Deposit(address indexed caller, address indexed token, uint256 amount);
  event UpdateBondAsset(address indexed token, bool status);
  event AddLiquidityToken(address indexed token);

  // The address of ald.
  address public immutable ald;

  // The address of Treasury.
  address public immutable treasury;

  // The address of Staking.
  address public staking;

  // Record whether an asset can be used to bond ALD.
  mapping(address => bool) public isBondAsset;
  // Record whether an asset is liquidity token.
  mapping(address => bool) public isLiquidityToken;

  // Mapping from asset address to total deposited amount.
  mapping(address => uint256) public totalPurchased;

  // The address of initializer to initialize staking address.
  address private _initializer;

  /// @param _ald The address of ALD token.
  /// @param _treasury The address of treasury.
  constructor(address _ald, address _treasury) {
    require(_ald != address(0), "DirectBondDepositor: not zero address");
    require(_treasury != address(0), "DirectBondDepositor: not zero address");

    ald = _ald;
    treasury = _treasury;

    _initializer = msg.sender;
  }

  /// @dev initialize staking address. Can only be called once.
  /// @param _staking The address of staking contract.
  function initialize(address _staking) external {
    require(_initializer == msg.sender, "DirectBondDepositor: only initializer");
    require(_staking != address(0), "DirectBondDepositor: not zero address");

    IERC20(ald).safeApprove(_staking, uint256(-1));
    staking = _staking;

    _initializer = address(0);
  }

  /********************************** View Functions **********************************/

  /// @dev return the amount of ALD could bond given token and amount.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function getBondALD(address _token, uint256 _amount) external view returns (uint256) {
    if (!isBondAsset[_token]) return 0;

    uint256 _value = ITreasury(treasury).valueOf(_token, _amount);
    return ITreasury(treasury).bondOf(_token, _value);
  }

  /********************************** Mutated Functions **********************************/

  /// @dev deposit token to bond ALD.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function deposit(
    address _token,
    uint256 _amount,
    uint256 _minBondAmount
  ) external nonReentrant {
    require(tx.origin == msg.sender, "DirectBondDepositor: only EOA");
    require(isBondAsset[_token], "DirectBondDepositor: not approved");

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    totalPurchased[_token] = totalPurchased[_token].add(_amount);

    uint256 _bondAmount;
    if (isLiquidityToken[_token]) {
      _bondAmount = ITreasury(treasury).deposit(ITreasury.ReserveType.LIQUIDITY_TOKEN, _token, _amount);
    } else {
      _bondAmount = ITreasury(treasury).deposit(ITreasury.ReserveType.UNDERLYING, _token, _amount);
    }

    require(_bondAmount >= _minBondAmount, "DirectBondDepositor: bond not enough");

    IStaking(staking).bondFor(msg.sender, _bondAmount);

    emit Deposit(msg.sender, _token, _amount);
  }

  /********************************** Restricted Functions **********************************/

  /// @dev update supported bond asset
  /// @param _token The address of token.
  /// @param _status Whether it is add or remove token.
  function updateBondAsset(address _token, bool _status) external onlyOwner {
    isBondAsset[_token] = _status;
    if (_status) {
      IERC20(_token).safeApprove(treasury, uint256(-1));
    } else {
      IERC20(_token).safeApprove(treasury, 0);
    }

    emit UpdateBondAsset(_token, _status);
  }

  /// @dev add liquidity token to bond asset.
  /// @param _pair The address of token.
  function addLiquidityToken(address _pair) external onlyOwner {
    require(
      IUniswapV2Pair(_pair).token0() == ald || IUniswapV2Pair(_pair).token1() == ald,
      "DirectBondDepositor: not supported"
    );

    isBondAsset[_pair] = true;
    isLiquidityToken[_pair] = true;

    IERC20(_pair).safeApprove(treasury, uint256(-1));

    emit AddLiquidityToken(_pair);
    emit UpdateBondAsset(_pair, true);
  }
}
