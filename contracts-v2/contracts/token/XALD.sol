// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IXALD.sol";

contract XALD is IXALD {
  using SafeMath for uint256;

  event MintShare(address recipient, uint256 share);
  event BurnShare(address account, uint256 share);
  event Rebase(uint256 epoch, uint256 profit);

  /**
   * @dev xALD balances are dynamic and are calculated based on the accounts' shares
   * and the total amount of staked ALD Token. Account shares aren't normalized, so
   * the contract also stores the sum of all shares to calculate each account's token
   * balance which equals to:
   *
   *   _shares[account] * _totalSupply / _totalShares
   */
  mapping(address => uint256) private _shares;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _totalShares;

  address public staking;

  address private _initializer;

  modifier onlyStaking() {
    require(msg.sender == staking, "XALD: only staking contract");
    _;
  }

  constructor() {
    _initializer = msg.sender;
  }

  function initialize(address _staking) external {
    require(_initializer == msg.sender, "XALD: only initializer");
    require(_staking != address(0), "XALD: not zero address");

    staking = _staking;
    _initializer = address(0);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public pure returns (string memory) {
    return "staked ALD Token";
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public pure returns (string memory) {
    return "xALD";
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   */
  function decimals() public pure returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Returns the total shares of sALD.
   */
  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address _account) public view override returns (uint256) {
    return getALDByShares(_shares[_account]);
  }

  /**
   * @return the amount of shares owned by `_account`.
   */
  function sharesOf(address _account) public view returns (uint256) {
    return _shares[_account];
  }

  /**
   * @dev See {IERC20-transfer}.
   */
  function transfer(address _recipient, uint256 _amount) public override returns (bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address _owner, address _spender) public view override returns (uint256) {
    return _allowances[_owner][_spender];
  }

  /**
   * @dev See {IERC20-approve}.
   */
  function approve(address _spender, uint256 _amount) public override returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   */
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) public override returns (bool) {
    uint256 currentAllowance = _allowances[_sender][msg.sender];
    require(currentAllowance >= _amount, "XALD: transfer amount exceeds allowance");

    _transfer(_sender, _recipient, _amount);
    _approve(_sender, msg.sender, currentAllowance.sub(_amount));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   */
  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    _approve(msg.sender, _spender, _allowances[msg.sender][_spender].add(_addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   */
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 currentAllowance = _allowances[msg.sender][_spender];
    require(currentAllowance >= _subtractedValue, "XALD: decreased allowance below zero");

    _approve(msg.sender, _spender, currentAllowance.sub(_subtractedValue));
    return true;
  }

  function stake(address _recipient, uint256 _aldAmount) external override onlyStaking {
    uint256 _sharesAmount = getSharesByALD(_aldAmount);
    _totalSupply = _totalSupply.add(_aldAmount);
    _mintShares(_recipient, _sharesAmount);
  }

  function unstake(address _account, uint256 _xALDAmount) external override onlyStaking {
    uint256 _sharesAmount = getSharesByALD(_xALDAmount);
    _totalSupply = _totalSupply.sub(_xALDAmount);
    _burnShares(_account, _sharesAmount);
  }

  function rebase(uint256 epoch, uint256 profit) external override onlyStaking {
    _totalSupply = _totalSupply.add(profit);

    emit Rebase(epoch, profit);
  }

  function getSharesByALD(uint256 _aldAmount) public view override returns (uint256) {
    uint256 totalPooledALD = _totalSupply;
    if (totalPooledALD == 0) {
      return _aldAmount;
    } else {
      return _aldAmount.mul(_totalShares).div(totalPooledALD);
    }
  }

  function getALDByShares(uint256 _sharesAmount) public view override returns (uint256) {
    uint256 totalShares_ = _totalShares;
    if (totalShares_ == 0) {
      return 0;
    } else {
      return _sharesAmount.mul(_totalSupply).div(totalShares_);
    }
  }

  /**
   * @dev Moves `_amount` tokens from `_sender` to `_recipient`.
   */
  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal {
    uint256 _sharesToTransfer = getSharesByALD(_amount);
    _transferShares(_sender, _recipient, _sharesToTransfer);
    emit Transfer(_sender, _recipient, _amount);
  }

  /**
   * @dev Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
   */
  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal {
    require(_owner != address(0), "XALD: approve from the zero address");
    require(_spender != address(0), "XALD: approve to the zero address");

    _allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  /**
   * @dev Moves `_sharesAmount` shares from `_sender` to `_recipient`.
   */
  function _transferShares(
    address _sender,
    address _recipient,
    uint256 _sharesAmount
  ) internal {
    require(_sender != address(0), "XALD: transfer from the zero address");
    require(_recipient != address(0), "XALD: transfer to the zero address");

    uint256 currentSenderShares = _shares[_sender];
    require(_sharesAmount <= currentSenderShares, "XALD: transfer amount exceeds balance");

    _shares[_sender] = currentSenderShares.sub(_sharesAmount);
    _shares[_recipient] = _shares[_recipient].add(_sharesAmount);
  }

  /**
   * @dev Creates `_sharesAmount` shares and assigns them to `_recipient`, increasing the total amount of shares.
   *
   * This doesn't increase the token total supply.
   */
  function _mintShares(address _recipient, uint256 _sharesAmount) internal {
    require(_recipient != address(0), "XALD: mint to the zero address");

    _totalShares = _totalShares.add(_sharesAmount);

    _shares[_recipient] = _shares[_recipient].add(_sharesAmount);

    emit MintShare(_recipient, _sharesAmount);
  }

  /**
   * @dev Destroys `_sharesAmount` shares from `_account`'s holdings, decreasing the total amount of shares.
   *
   * This doesn't decrease the token total supply.
   */
  function _burnShares(address _account, uint256 _sharesAmount) internal {
    require(_account != address(0), "XALD: burn from the zero address");

    uint256 accountShares = _shares[_account];
    require(_sharesAmount <= accountShares, "XALD: burn amount exceeds balance");

    _totalShares = _totalShares.sub(_sharesAmount);

    _shares[_account] = accountShares.sub(_sharesAmount);

    emit BurnShare(_account, _sharesAmount);
  }
}
