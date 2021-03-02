pragma solidity 0.6.12;

import "../common/IERC20.sol";
import "../common/SafeERC20.sol";
import "../common/SafeMath.sol";
import "../common/Ownable.sol";
import "./ALDToken.sol";

// Forked from the original SushiMaster contract (https://github.com/sushiswap/sushiswap/blob/master/contracts/SushiMaker.sol) with the following changes:
// - Add mechanism allow changing reward multpliers on a scheduled timeline
// - Style changes 

contract TokenMaster is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STRUCTS ========== */

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
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
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ALDs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ALDs distribution occurs.
        uint256 accALDPerShare; // Accumulated ALDs per share, times 1e12. See below.
    }

    /* ========== STATE VARIABLES ========== */

    // The ALD TOKEN!
    ALDToken public ALD;
    // token distributor address.
    address public tokenDistributor;

    // The block number when ALD mining starts.
    uint256 public startBlock;
    // ALD tokens created per block.
    uint256 public ALDPerBlock = 10;
    // Bonus muliplier for early ALD makers.
    uint256[] public REWARD_MULTIPLIER = [1000, 100, 10, 1, 0];
    // Reward muliplier duration
    uint256 public BLOCKS_PER_MULTIPLIER = 86400; // 5 days for 5s block time
    // Array of block numbers where reward multiplier changes.
    uint256[] public CHANGE_MULTIPLIER_AT_BLOCK; // init in constructor

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        ALDToken _ALD,
        address _tokenDistributor
    ) public {
        ALD = _ALD;
        tokenDistributor = _tokenDistributor;
        startBlock = block.number;

        for (uint256 i = 0; i < REWARD_MULTIPLIER.length - 1; i++) {
            uint256 changeMultiplierAtBlock = startBlock.add(BLOCKS_PER_MULTIPLIER.mul(i+1));
            CHANGE_MULTIPLIER_AT_BLOCK.push(changeMultiplierAtBlock);
        }
        CHANGE_MULTIPLIER_AT_BLOCK.push(uint256(-1));
    }

    /* ========== VIEW FUNCTONS ========== */

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < CHANGE_MULTIPLIER_AT_BLOCK.length; i++) {
            uint256 endBlock = CHANGE_MULTIPLIER_AT_BLOCK[i];

            if (_to <= endBlock) {
                uint256 m = _to.sub(_from).mul(REWARD_MULTIPLIER[i]);
                return result.add(m);
            }

            if (_from < endBlock) {
                uint256 m = endBlock.sub(_from).mul(REWARD_MULTIPLIER[i]);
                _from = endBlock;
                result = result.add(m);
            }
        }
        return result;
    }

    // View function to see pending ALDs on frontend.
    function pendingALD(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accALDPerShare = pool.accALDPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ALDReward = multiplier.mul(ALDPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accALDPerShare = accALDPerShare.add(ALDReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accALDPerShare).div(1e12).sub(user.rewardDebt);
    }

    /* ========== USER MUTATIVE FUNCTONS ========== */

    // Deposit LP tokens to TokenMaster for ALD allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accALDPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeALDTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accALDPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from TokenMaster.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accALDPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeALDTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accALDPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /* ========== SYSTEM MUTATIVE FUNCTONS ========== */

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 ALDReward = multiplier.mul(ALDPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        ALD.mint(tokenDistributor, ALDReward.div(10));
        ALD.mint(address(this), ALDReward);
        pool.accALDPerShare = pool.accALDPerShare.add(ALDReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    /* ========== INTERNAL FUNCTONS ========== */

    // Safe ALD transfer function, just in case if rounding error causes pool to not have enough ALDs.
    function safeALDTransfer(address _to, uint256 _amount) internal {
        uint256 ALDBal = ALD.balanceOf(address(this));
        if (_amount > ALDBal) {
            ALD.transfer(_to, ALDBal);
        } else {
            ALD.transfer(_to, _amount);
        }
    }

    /* ========== RESTRICTED FUNCTONS ========== */

    // Update token distributor address.
    function setTokenDistributor(address _tokenDistributor) public onlyOwner {
        tokenDistributor = _tokenDistributor;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accALDPerShare: 0
        }));
    }

    // Update the given pool's ALD allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update Rewards Mulitplier Array
    function setRewardMul(uint256[] memory _newMulReward) public onlyOwner {
        REWARD_MULTIPLIER = _newMulReward;
    }

    // Update Halving At Block
    function setChangeMulAtBlock(uint256[] memory _newChangeMul) public onlyOwner {
        CHANGE_MULTIPLIER_AT_BLOCK = _newChangeMul;
    }
}
