pragma solidity 0.6.12;

import "./BaseStrategy.sol";

interface MasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 _amount, uint256 _rewardDebt);
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
    function emergencyWithdraw(uint256 _pid) external;
}

contract StrategySushiETHWBTC is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address constant public lpETHWBTC = address(0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58); // want
    address constant public SUSHI = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2); // reward
    address constant public masterChef = address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    uint256 constant public pidWant = 21;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _controller)
      public
      BaseStrategy(_controller, lpETHWBTC, SUSHI)
    {

    }

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual override returns (string memory) {
        return "StrategySushiETHWBTC";
    }

    function balanceOf() public view virtual override returns (uint) {
        return balanceOfWant()
               .add(balanceOfWantInMasterChef());
    }

    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfWantInMasterChef() public view returns (uint balance_) {
        (, balance_) = MasterChef(masterChef).userInfo(pidWant, address(this));
    }

    function pendingRewards() public view returns (uint) {
        return MasterChef(masterChef).pendingSushi(pidWant, address(this));
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit() internal virtual override {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChef, 0);
            IERC20(want).safeApprove(masterChef, _want);
            MasterChef(masterChef).deposit(pidWant, _want);
        }
    }

    function _claimReward() internal virtual override {
        MasterChef(masterChef).deposit(pidWant, 0);
    }

    function _withdrawSome(uint _amount) internal virtual override returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        MasterChef(masterChef).withdraw(pidWant, _amount);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
        return _withdrew;
    }

    function _withdrawAll() internal virtual override {
        _withdrawSome(balanceOfWantInMasterChef());
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function emergencyWithdrawWithoutRewards() external {
        // in case something goes wrong with master chef, allow governance to rescue funds
        require(msg.sender == governance, "!governance");
        MasterChef(masterChef).emergencyWithdraw(pidWant);

        // sent token back to vault
        uint _balance = IERC20(want).balanceOf(address(this));
        address _vault = IController(controller).vaults(address(this));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _balance);
    }
}
