// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../common/IERC20.sol";
import "../../common/ERC20.sol";
import "../../common/SafeERC20.sol";
import "../../common/SafeMath.sol";
import "../../common/Address.sol";
import "../../common/ReentrancyGuard.sol";

import "../../interfaces/ITokenMaster.sol";

abstract contract BaseMultiRewardVault is ERC20, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ========== STATE VARIABLES ========== */

  // Addresses
  IERC20 public token;
  address public governance;
  address public tokenMaster;
  address public treasury;

  // Rewards
  IERC20[] public rewardTokens;
  uint256[] public rewardsPerShareStored;
  /// mapping from user address to reward index to reward per share paid.
  mapping(address => mapping(uint256 => uint256)) public userRewardPerSharePaid;
  /// mapping from user address to reward index to reward amount.
  mapping(address => mapping(uint256 => uint256)) public rewards;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _token,
    address _treasury,
    address _tokenMaster
  )
    public
    ERC20(
      string(abi.encodePacked("aladdin ", ERC20(_token).name())),
      string(abi.encodePacked("ald", ERC20(_token).symbol()))
    )
  {
    _setupDecimals(ERC20(_token).decimals());
    token = IERC20(_token);
    treasury = _treasury;
    tokenMaster = _tokenMaster;
    governance = msg.sender;
  }

  function _setupRewardTokens(address[] memory _rewardsToken) internal {
    for (uint256 i = 0; i < _rewardsToken.length; i++) {
      rewardTokens.push(IERC20(_rewardsToken[i]));
      rewardsPerShareStored.push(0);
    }
  }

  /* ========== VIEWS ========== */

  // Balance of deposit token owned by vault
  function balance() public view returns (uint256) {
    return token.balanceOf(address(this)).add(_balanceOf());
  }

  // Amount of deposit token per vault share
  function getPricePerFullShare() public view returns (uint256) {
    return balance().mul(1e18).div(totalSupply());
  }

  // Amount of shares staked in token master
  function stakedBalanceOf(address _user) public view returns (uint256) {
    return ITokenMaster(tokenMaster).userBalanceForPool(_user, address(this));
  }

  // Amount of reward token earned for user
  function earned(address account) public view returns (uint256[] memory) {
    uint256 totalBalance = balanceOf(account).add(stakedBalanceOf(account));
    uint256 totalRewardTokens = rewardTokens.length;
    uint256[] memory _rewards = new uint256[](totalRewardTokens);
    for (uint256 i = 0; i < totalRewardTokens; i++) {
      _rewards[i] = totalBalance.mul(rewardsPerShareStored[i].sub(userRewardPerSharePaid[account][i])).div(1e18).add(
        rewards[account][i]
      );
    }
    return _rewards;
  }

  /* ========== USER MUTATIVE FUNCTIONS ========== */

  function deposit(uint256 _amount) external nonReentrant {
    _updateReward(msg.sender);

    uint256 _pool = balance();
    token.safeTransferFrom(msg.sender, address(this), _amount);

    uint256 shares = 0;
    if (totalSupply() == 0) {
      shares = _amount;
    } else {
      shares = (_amount.mul(totalSupply())).div(_pool);
    }

    // Mint vault share
    _mint(msg.sender, shares);
    // Deposit token into strategy
    _deposit();

    emit Deposit(msg.sender, _amount);
  }

  function withdraw(uint256 _shares) public nonReentrant {
    _updateReward(msg.sender);

    uint256 r = (balance().mul(_shares)).div(totalSupply());
    _burn(msg.sender, _shares);

    // Check balance
    uint256 b = token.balanceOf(address(this));
    if (b < r) {
      uint256 _withdrawAmount = r.sub(b);
      // Withdraw from strategy
      _withdraw(_withdrawAmount);
      uint256 _after = token.balanceOf(address(this));
      uint256 _diff = _after.sub(b);
      if (_diff < _withdrawAmount) {
        r = b.add(_diff);
      }
    }

    token.safeTransfer(msg.sender, r);
    emit Withdraw(msg.sender, r);
  }

  function claim() public {
    _updateReward(msg.sender);

    // need to discuss
    /*
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardToken.safeTransfer(msg.sender, reward);
    }
    emit Claim(msg.sender, reward);
    */
  }

  function exit() external {
    withdraw(balanceOf(msg.sender));
    claim();
  }

  /* ========== KEEPER MUTATIVE FUNCTIONS ========== */

  // Call harvest() to claim rewards from strategy
  // harvest() is marked as nonReentrant to prevent sandwich/MEV attack to collect most rewards through a flash-deposit() follow by a claim
  function harvest() external nonReentrant {
    IERC20[] memory _rewardTokens = rewardTokens;
    uint256[] memory _rewardsBefore = new uint256[](_rewardTokens.length);
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      _rewardsBefore[i] = _rewardTokens[i].balanceOf(address(this));
    }

    // Harvest rewards from strategy
    _harvest();

    uint256 _totalSupply = totalSupply();
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 _rewardAfter = _rewardTokens[i].balanceOf(address(this));
      uint256 harvested = _rewardAfter.sub(_rewardsBefore[i]);

      // all rewards are transfered to treasury
      _rewardTokens[i].safeTransfer(treasury, harvested);

      // distribute new rewards to current shares evenly
      rewardsPerShareStored[i] = rewardsPerShareStored[i].add(harvested.mul(1e18).div(_totalSupply));

      emit Harvest(msg.sender, address(_rewardTokens[i]), harvested);
    }
  }

  /* ========== STRATEGY FUNCTIONS ========== */

  // All vault implementation should extend the following interfaces

  // Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal virtual;

  // Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal virtual;

  // Harvest rewards from strategy into vault
  function _harvest() internal virtual;

  // Balance of deposit token in underlying strategy
  function _balanceOf() internal view virtual returns (uint256);

  /* ========== INTERNAL FUNCTIONS ========== */

  function _updateReward(address account) internal {
    uint256 totalRewardsToken = rewardTokens.length;
    uint256[] memory _rewards = earned(account);
    for (uint256 i = 0; i < totalRewardsToken; i++) {
      rewards[account][i] = _rewards[i];
      userRewardPerSharePaid[account][i] = rewardsPerShareStored[i];
    }
  }

  // Override underlying transfer function to update reward before transfer, except on staking/withdraw to token master
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    if (to != tokenMaster && from != tokenMaster) {
      // No need to update reward on `_mint` or `_burn`.
      if (from != address(0)) {
        _updateReward(from);
      }
      if (to != address(0)) {
        _updateReward(to);
      }
    }

    super._beforeTokenTransfer(from, to, amount);
  }

  /* ========== GOVERNANCE FUNCTIONS ========== */

  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setTokenMaster(address _tokenMaster) external {
    require(msg.sender == governance, "!governance");
    tokenMaster = _tokenMaster;
  }

  function inCaseTokensGetStuck(IERC20 _token, uint256 _amount) public {
    require(msg.sender == governance, "!governance");

    // Not allowed withdraw vault tokens.
    if (_token == token) return;
    uint256 totalRewardTokens = rewardTokens.length;
    for (uint256 i = 0; i < totalRewardTokens; i++) {
      if (rewardTokens[i] == _token) return;
    }

    IERC20(_token).safeTransfer(msg.sender, _amount);
  }

  /* ========== EVENTS ========== */

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event Harvest(address indexed keeper, address token, uint256 harvestedAmount);
}
