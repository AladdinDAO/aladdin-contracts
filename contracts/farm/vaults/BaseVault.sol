pragma solidity 0.6.12;

import "../../common/IERC20.sol";
import "../../common/ERC20.sol";
import "../../common/SafeERC20.sol";
import "../../common/SafeMath.sol";
import "../../common/Address.sol";
import "../../common/ReentrancyGuard.sol";

import "../../interfaces/IController.sol";
import "../../interfaces/ITokenMaster.sol";

// Forked from the original yearn yVault (https://github.com/yearn/yearn-protocol/blob/develop/contracts/vaults/yVault.sol) with the following changes:
// - Introduce reward token of which the user can claim from the underlying strategy
// - Keeper fees for farm and harvest
// - Overriding transfer function to avoid reward token accumulation in TokenMaster (e.g when user stake Vault token into TokenMaster)

abstract contract BaseVault is ERC20, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ========== STATE VARIABLES ========== */

  IERC20 public token;
  IERC20 public rewardToken;

  uint public availableMin = 9500;
  uint public farmKeeperFeeMin = 0;
  uint public harvestKeeperFeeMin = 0;
  uint public constant MAX = 10000;

  uint public rewardsPerShareStored;
  mapping(address => uint256) public userRewardPerSharePaid;
  mapping(address => uint256) public rewards;

  address public governance;
  address public controller;
  address public tokenMaster;
  mapping(address => bool) public keepers;

  /* ========== CONSTRUCTOR ========== */

  constructor (
      address _token,
      address _rewardToken,
      address _controller,
      address _tokenMaster)
      public
      ERC20 (
        string(abi.encodePacked("aladdin ", ERC20(_token).name())),
        string(abi.encodePacked("ald", ERC20(_token).symbol())
      )
  ) {
      _setupDecimals(ERC20(_token).decimals());
      token = IERC20(_token);
      rewardToken = IERC20(_rewardToken);
      controller = _controller;
      governance = msg.sender;
      tokenMaster = _tokenMaster;
  }

  /* ========== VIEWS ========== */

  function balance() public view returns (uint) {
      return token.balanceOf(address(this))
             .add(IController(controller).balanceOf(address(this)));
  }

  // Custom logic in here for how much the vault allows to be borrowed
  // Sets minimum required on-hand to keep small withdrawals cheap
  function available() public view returns (uint) {
      return token.balanceOf(address(this)).mul(availableMin).div(MAX);
  }

  function getPricePerFullShare() public view returns (uint) {
      return balance().mul(1e18).div(totalSupply());
  }

  // amount staked in token master
  function stakedBalanceOf(address _user) public view returns(uint) {
      return ITokenMaster(tokenMaster).userBalanceForPool(_user, address(this));
  }

  function earned(address account) public view returns (uint) {
      uint256 totalBalance = balanceOf(account).add(stakedBalanceOf(account));
      return totalBalance.mul(rewardsPerShareStored.sub(userRewardPerSharePaid[account])).div(1e18).add(rewards[account]);
  }

  /* ========== USER MUTATIVE FUNCTIONS ========== */

  function deposit(uint _amount) external nonReentrant {
      _updateReward(msg.sender);

      uint _pool = balance();
      token.safeTransferFrom(msg.sender, address(this), _amount);

      uint shares = 0;
      if (totalSupply() == 0) {
        shares = _amount;
      } else {
        shares = (_amount.mul(totalSupply())).div(_pool);
      }
      _mint(msg.sender, shares);
      emit Deposit(msg.sender, _amount);
  }

  // No rebalance implementation for lower fees and faster swaps
  function withdraw(uint _shares) public nonReentrant {
      _updateReward(msg.sender);

      uint r = (balance().mul(_shares)).div(totalSupply());
      _burn(msg.sender, _shares);

      // Check balance
      uint b = token.balanceOf(address(this));
      if (b < r) {
          uint _withdraw = r.sub(b);
          IController(controller).withdraw(address(this), _withdraw);
          uint _after = token.balanceOf(address(this));
          uint _diff = _after.sub(b);
          if (_diff < _withdraw) {
              r = b.add(_diff);
          }
      }

      token.safeTransfer(msg.sender, r);
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

  // Override underlying transfer function to update reward before transfer, except on staking/withdraw to token master
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override
  {
      if (to != tokenMaster && from != tokenMaster) {
          _updateReward(from);
          _updateReward(to);
      }

      super._beforeTokenTransfer(from, to, amount);
  }

  /* ========== KEEPER MUTATIVE FUNCTIONS ========== */

  // Keepers call farm() to send funds to strategy
  function farm() external onlyKeeper {
      uint _bal = available();

      uint keeperFee = _bal.mul(farmKeeperFeeMin).div(MAX);
      if (keeperFee > 0) {
          token.safeTransfer(msg.sender, keeperFee);
      }

      uint amountLessFee = _bal.sub(keeperFee);
      token.safeTransfer(controller, amountLessFee);
      IController(controller).farm(address(this), amountLessFee);

      emit Farm(msg.sender, keeperFee, amountLessFee);
  }

  // Keepers call harvest() to claim rewards from strategy
  // harvest() is marked as onlyEOA to prevent sandwich/MEV attack to collect most rewards through a flash-deposit() follow by a claim
  function harvest() external onlyKeeper {
      uint _rewardBefore = rewardToken.balanceOf(address(this));
      IController(controller).harvest(address(this));
      uint _rewardAfter = rewardToken.balanceOf(address(this));

      uint harvested = _rewardAfter.sub(_rewardBefore);
      uint keeperFee = harvested.mul(harvestKeeperFeeMin).div(MAX);
      if (keeperFee > 0) {
          rewardToken.safeTransfer(msg.sender, keeperFee);
      }

      uint newRewardAmount = harvested.sub(keeperFee);
      // distribute new rewards to current shares evenly
      rewardsPerShareStored = rewardsPerShareStored.add(newRewardAmount.mul(1e18).div(totalSupply()));

      emit Harvest(msg.sender, keeperFee, newRewardAmount);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  function _updateReward(address account) internal {
      rewards[account] = earned(account);
      userRewardPerSharePaid[account] = rewardsPerShareStored;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setAvailableMin(uint _availableMin) external {
      require(msg.sender == governance, "!governance");
      require(_availableMin < MAX, "over MAX");
      availableMin = _availableMin;
  }

  function setFarmKeeperFeeMin(uint _farmKeeperFeeMin) external {
      require(msg.sender == governance, "!governance");
      require(_farmKeeperFeeMin < MAX, "over MAX");
      farmKeeperFeeMin = _farmKeeperFeeMin;
  }

  function setHarvestKeeperFeeMin(uint _harvestKeeperFeeMin) external {
      require(msg.sender == governance, "!governance");
      require(_harvestKeeperFeeMin < MAX, "over MAX");
      harvestKeeperFeeMin = _harvestKeeperFeeMin;
  }

  function setGovernance(address _governance) external {
      require(msg.sender == governance, "!governance");
      governance = _governance;
  }

  function setController(address _controller) external {
      require(msg.sender == governance, "!governance");
      controller = _controller;
  }

  function setTokenMaster(address _tokenMaster) external {
      require(msg.sender == governance, "!governance");
      tokenMaster = _tokenMaster;
  }

  function addKeeper(address _address) external {
      require(msg.sender == governance, "!governance");
      keepers[_address] = true;
  }

  function removeKeeper(address _address) external {
      require(msg.sender == governance, "!governance");
      keepers[_address] = false;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyKeeper() {
      require(keepers[msg.sender] == true, "!keeper");
       _;
  }

  /* ========== EVENTS ========== */

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event Farm(address indexed keeper, uint256 keeperFee, uint256 farmedAmount);
  event Harvest(address indexed keeper, uint256 keeperFee, uint256 harvestedAmount);
}
