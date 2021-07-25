pragma solidity 0.6.12;

import "../common/IERC20.sol";
import "../common/SafeERC20.sol";
import "../common/SafeMath.sol";
import "../common/Ownable.sol";
import "../common/ReentrancyGuard.sol";
import "./ALDToken.sol";

contract TokenMaster is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ALDs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accALDPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accALDPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ALDs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ALDs distribution occurs.
        uint256 accALDPerShare; // Accumulated ALDs per share, times 1e18. See below.
    }

    // The ALD TOKEN!
    ALDToken public ald;
    // Token distributor address
    address public tokenDistributor;
    // token distributor reward allocation = total reward emission * tokenDistributorAllocNume / tokenDistributorAllocDenom
    uint256 public tokenDistributorAllocNume = 6000;
    uint256 constant public tokenDistributorAllocDenom = 10000;
    // ALD tokens created per block.
    uint256 public aldPerBlock;
    // mapping of token to pool id
    mapping(address => uint) public tokenToPid;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ALD mining starts.
    uint256 public startBlock;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        ALDToken _ald,
        address _tokenDistributor,
        uint256 _aldPerBlock,
        uint256 _startBlock
    ) public {
        ald = _ald;
        tokenDistributor = _tokenDistributor;
        aldPerBlock = _aldPerBlock;
        startBlock = _startBlock;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function userBalanceForPool(address _user, address _poolToken) external view returns (uint256) {
        uint pid = tokenToPid[_poolToken];
        if (pid == 0) {
          // pool does not exist
          return 0;
        }
        UserInfo storage user = userInfo[pid][_user];
        return user.amount;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending ALDs on frontend.
    function pendingALD(address _token, address _user) onlyValidPool(_token) external view returns (uint256) {
        uint pid = tokenToPid[_token];
        PoolInfo storage pool = poolInfo[pid - 1];
        UserInfo storage user = userInfo[pid][_user];
        uint256 accALDPerShare = pool.accALDPerShare;
        uint256 lpSupply = IERC20(pool.token).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 aldReward = aldPerBlock.mul(block.number.sub(pool.lastRewardBlock))
                                             .mul(pool.allocPoint)
                                             .div(totalAllocPoint);
            uint256 distributorReward = aldReward.mul(tokenDistributorAllocNume).div(tokenDistributorAllocDenom);
            uint256 poolReward = aldReward.sub(distributorReward);
            accALDPerShare = accALDPerShare.add(poolReward.mul(1e18).div(lpSupply));
        }
        return user.amount.mul(accALDPerShare).div(1e18).sub(user.rewardDebt);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 1; pid <= length; ++pid) {
            PoolInfo storage pool = poolInfo[pid - 1];
            updatePool(pool.token);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(address _token) onlyValidPool(_token) public {
        uint pid = tokenToPid[_token];
        PoolInfo storage pool = poolInfo[pid - 1];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(pool.token).balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // get total pool rewards in since last update
        uint256 aldReward = aldPerBlock.mul(block.number.sub(pool.lastRewardBlock))
                                         .mul(pool.allocPoint)
                                         .div(totalAllocPoint);

        // mint distributor portion
        uint256 distributorReward = aldReward.mul(tokenDistributorAllocNume).div(tokenDistributorAllocDenom);
        ald.mint(tokenDistributor, distributorReward);

        // update pool rewards
        uint256 poolReward = aldReward.sub(distributorReward);
        ald.mint(address(this), poolReward);
        pool.accALDPerShare = pool.accALDPerShare.add(
            poolReward.mul(1e18).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens for ALD allocation.
    function deposit(address _token, uint256 _amount) onlyValidPool(_token) external nonReentrant {
        uint pid = tokenToPid[_token];
        PoolInfo storage pool = poolInfo[pid - 1];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pool.token);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accALDPerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                safeALDTransferToStaker(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            IERC20(pool.token).safeTransferFrom(address(msg.sender), address(this),_amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accALDPerShare).div(1e18);
        emit Deposit(msg.sender, _token, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(address _token, uint256 _amount) onlyValidPool(_token) external {
        uint pid = tokenToPid[_token];
        PoolInfo storage pool = poolInfo[pid - 1];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(pool.token);
        uint256 pending = user.amount.mul(pool.accALDPerShare).div(1e18).sub(user.rewardDebt);
        if(pending > 0) {
            safeALDTransferToStaker(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IERC20(pool.token).safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accALDPerShare).div(1e18);
        emit Withdraw(msg.sender, _token, _amount);
    }

    // Claim pending rewards for all pools
    function claimAll() external {
        massUpdatePools();
        uint256 pending;
        for (uint pid = 1; pid <= poolInfo.length; pid++) {
            PoolInfo storage pool = poolInfo[pid - 1];
            UserInfo storage user = userInfo[pid][msg.sender];
            if (user.amount > 0) {
                pending = pending.add(user.amount.mul(pool.accALDPerShare).div(1e18).sub(user.rewardDebt));
                user.rewardDebt = user.amount.mul(pool.accALDPerShare).div(1e18);
            }
        }
        if (pending > 0) {
            safeALDTransferToStaker(msg.sender, pending);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _token) onlyValidPool(_token) external nonReentrant {
        uint pid = tokenToPid[_token];
        PoolInfo storage pool = poolInfo[pid - 1];
        UserInfo storage user = userInfo[pid][msg.sender];
        user.amount = 0;
        user.rewardDebt = 0;
        IERC20(pool.token).safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _token, user.amount);
    }

    // Safe ald transfer function, just in case if rounding error causes pool to not have enough ALDs.
    function safeALDTransferToStaker(address _user, uint256 _amount) internal {
        uint256 aldBal = ald.balanceOf(address(this));
        if (_amount > aldBal) {
            ald.transfer(_user, aldBal);
        } else {
            ald.transfer(_user, _amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, address _token, bool _withUpdate) external onlyOwner checkDuplicatePool(_token) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accALDPerShare: 0
            })
        );
        tokenToPid[_token] = poolInfo.length; // pid 0 reserved for 'pool does not exist'
    }

    // Update the given pool's ALD allocation point. Can only be called by the owner.
    function set(address _token, uint256 _allocPoint) external onlyOwner onlyValidPool(_token){
        massUpdatePools();
        uint pid = tokenToPid[_token];
        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid - 1].allocPoint).add(_allocPoint);
        poolInfo[pid - 1].allocPoint = _allocPoint;
    }

    function setALDPerBlock(uint256 _aldPerBlock) external onlyOwner {
        // mass update pools before updating reward rate to avoid changing pending rewards
        massUpdatePools();
        aldPerBlock = _aldPerBlock;
    }

    function setTokenDistributor(address _tokenDistributor) external onlyOwner {
        tokenDistributor = _tokenDistributor;
    }

    function setTokenDistributorAllocNume(uint256 _tokenDistributorAllocNume) external onlyOwner {
        require(_tokenDistributorAllocNume <= tokenDistributorAllocDenom, "Numerator cannot be larger than denominator");
        tokenDistributorAllocNume = _tokenDistributorAllocNume;
    }

    function setStartBlock(uint256 _startBlock) external onlyOwner {
        require(block.number < startBlock, "Cannot change startBlock after reward start");
        startBlock = _startBlock;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyValidPool(address _token) {
        uint pid = tokenToPid[_token];
        require(pid != 0, "pool does not exist");
        _;
    }

    modifier checkDuplicatePool(address _token) {
        for (uint256 pid = 1; pid <= poolInfo.length; pid++) {
            require(poolInfo[pid - 1].token != _token,  "pool already exist");
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed token, uint256 amount);
}
