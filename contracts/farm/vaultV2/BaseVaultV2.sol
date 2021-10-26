// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../common/IERC20.sol";
import "../../common/ERC20.sol";
import "../../common/SafeERC20.sol";
import "../../common/SafeMath.sol";
import "../../common/Address.sol";
import "../../common/ReentrancyGuard.sol";

import "../../interfaces/ITokenMaster.sol";
import "../../interfaces/IWETH.sol";

abstract contract BaseVaultV2 is ERC20, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ========== STATE VARIABLES ========== */

  // Addresses
  address private immutable WETH;

  IERC20 public token;
  IERC20 public rewardToken;
  address public governance;
  address public tokenMaster;
  address public treasury;

  // Fees
  uint public performanceFeeMin = 2000;
  uint public constant MAX = 10000;

  // Rewards
  uint public rewardsPerShareStored;
  mapping(address => uint256) public userRewardPerSharePaid;
  mapping(address => uint256) public rewards;

  /* ========== CONSTRUCTOR ========== */

  constructor (
      address _weth,
      address _token,
      address _rewardToken,
      address _treasury,
      address _tokenMaster)
      public
      ERC20 (
        string(abi.encodePacked("aladdin ", ERC20(_token).name())),
        string(abi.encodePacked("ald", ERC20(_token).symbol())
      )
  ) {
      _setupDecimals(ERC20(_token).decimals());
      WETH = _weth;
      token = IERC20(_token);
      rewardToken = IERC20(_rewardToken);
      treasury = _treasury;
      tokenMaster = _tokenMaster;
      governance = msg.sender;
  }

  /* ========== VIEWS ========== */

  // Balance of deposit token owned by vault
  function balance() public view returns (uint) {
      return token.balanceOf(address(this))
             .add(_balanceOf());
  }

  // Amount of deposit token per vault share
  function getPricePerFullShare() public view returns (uint) {
      return balance().mul(1e18).div(totalSupply());
  }

  // Amount of shares staked in token master
  function stakedBalanceOf(address _user) public view returns(uint) {
      return ITokenMaster(tokenMaster).userBalanceForPool(_user, address(this));
  }

  // Amount of reward token earned for user
  function earned(address account) public view returns (uint) {
      uint256 totalBalance = balanceOf(account).add(stakedBalanceOf(account));
      return totalBalance.mul(rewardsPerShareStored.sub(userRewardPerSharePaid[account])).div(1e18).add(rewards[account]);
  }

  /* ========== USER MUTATIVE FUNCTIONS ========== */

  function deposit(uint _amount) payable external nonReentrant {
      _updateReward(msg.sender);

      uint _pool = balance();

      // special deal with WETH
      if (msg.value > 0) {
        require(msg.value == _amount, "msg.value mismatch _amount");
        require(address(token) == WETH, "asset is not WETH");
        IWETH(WETH).deposit{value: msg.value}();
      } else {
        token.safeTransferFrom(msg.sender, address(this), _amount);
      }

      uint shares = 0;
      uint _totalSupply = totalSupply();
      if (_totalSupply == 0) {
        shares = _amount;
      } else {
        shares = (_amount.mul(_totalSupply)).div(_pool);
      }

      // Mint vault share
      _mint(msg.sender, shares);
      // Deposit token into strategy
      _deposit();

      emit Deposit(msg.sender, _amount);
  }

  function withdraw(uint _shares) public nonReentrant {
      _updateReward(msg.sender);

      uint r = (balance().mul(_shares)).div(totalSupply());
      _burn(msg.sender, _shares);

      IERC20 _token = token; // gas saving
      // Check balance
      uint b = _token.balanceOf(address(this));
      if (b < r) {
          uint _withdrawAmount = r.sub(b);
          // Withdraw from strategy
          _withdraw(_withdrawAmount);
          uint _after = _token.balanceOf(address(this));
          uint _diff = _after.sub(b);
          if (_diff < _withdrawAmount) {
              r = b.add(_diff);
          }
      }
      
      // special deal with WETH
      if (address(_token) == WETH) {
        IWETH(address(_token)).withdraw(r);
        Address.sendValue(msg.sender, r);
      } else {
        _token.safeTransfer(msg.sender, r);
      }
      emit Withdraw(msg.sender, r);
  }

  function claim() public {
      _updateReward(msg.sender);

      uint reward = rewards[msg.sender];
      if (reward > 0) {
          rewards[msg.sender] = 0;
          rewardToken.safeTransfer(msg.sender, reward);
      }
      emit Claim(msg.sender, reward);
  }

  function exit() external {
      withdraw(balanceOf(msg.sender));
      claim();
  }

  /* ========== KEEPER MUTATIVE FUNCTIONS ========== */

  // Call harvest() to claim rewards from strategy
  // harvest() is marked as nonReentrant to prevent sandwich/MEV attack to collect most rewards through a flash-deposit() follow by a claim
  function harvest() external nonReentrant {
      uint _rewardBefore = rewardToken.balanceOf(address(this));
      // Harvest rewards from strategy
      _harvest();
      uint _rewardAfter = rewardToken.balanceOf(address(this));

      uint harvested = _rewardAfter.sub(_rewardBefore);
      uint performanceFee = harvested.mul(performanceFeeMin).div(MAX);
      if (performanceFee > 0) {
          rewardToken.safeTransfer(treasury, performanceFee);
      }

      uint newRewardAmount = harvested.sub(performanceFee);
      // distribute new rewards to current shares evenly
      rewardsPerShareStored = rewardsPerShareStored.add(newRewardAmount.mul(1e18).div(totalSupply()));

      emit Harvest(msg.sender, performanceFee, newRewardAmount);
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
      rewards[account] = earned(account);
      userRewardPerSharePaid[account] = rewardsPerShareStored;
  }

  // Override underlying transfer function to update reward before transfer, except on staking/withdraw to token master
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override
  {
      if (to != tokenMaster && from != tokenMaster) {
          _updateReward(from);
          _updateReward(to);
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

  function setPerformanceFeeMin(uint _performanceFeeMin) external {
      require(msg.sender == governance, "!governance");
      require(_performanceFeeMin <= MAX, "over MAX");
      performanceFeeMin = _performanceFeeMin;
  }

  // to receive from WETH
  receive() external payable {}

  /* ========== EVENTS ========== */

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event Harvest(address indexed keeper, uint256 performanceFee, uint256 harvestedAmount);
}
