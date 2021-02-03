pragma solidity 0.6.12;

import "../../common/IERC20.sol";
import "../../common/SafeMath.sol";
import "../../common/Address.sol";
import "../../common/SafeERC20.sol";

interface Controller {
    function vaults(address) external view returns (address);
    function strategies(address) external view returns (address);
    function rewards() external view returns (address);
    function approveStrategy(address, address) external;
    function setStrategy(address, address) external;
    function approvedStrategies(address, address) external view returns (bool);
    function withdrawAll(address) external;
}

/*

 A strategy must implement the following calls;

 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - harvest() - Controller | Vault role - harvest should always send to vault
 - balanceOf()

 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller

*/

abstract contract BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public want;
    address public reward;

    address public governance;
    address public controller;
    address public strategist;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _controller,
        address _want,
        address _reward
    ) public {
        governance = msg.sender;
        strategist = msg.sender;
        controller = _controller;
        want = _want;
        reward = _reward;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance || msg.sender == strategist, "!gs");
        strategist = _strategist;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit() external {
        _deposit();
    }

    function harvest() external {
        _claimReward();

        uint balance = IERC20(reward).balanceOf(address(this));
        address _vault = Controller(controller).vaults(address(this));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(reward).safeTransfer(_vault, balance);
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");

        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        address _vault = Controller(controller).vaults(address(this));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _vault = Controller(controller).vaults(address(this));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit() internal virtual;

    function _claimReward() internal virtual;

    function _withdrawSome(uint _amount) internal virtual returns (uint);

    function _withdrawAll() internal virtual;

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual returns (string memory);

    function balanceOf() public view virtual returns (uint);
}
