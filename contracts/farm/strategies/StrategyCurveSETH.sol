pragma solidity 0.6.12;

import "./BaseStrategy.sol";

interface Gauge {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
}

interface Mintr {
    function mint(address _gauge) external;
}

contract StrategyCurveSETH is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address constant public eCRV = address(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c); // want
    address constant public CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // reward
    address constant public gauge = address(0x3C0FFFF15EA30C35d7A85B85c0782D6c94e1d238);
    address constant public mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _controller)
      public
      BaseStrategy(_controller, eCRV, CRV)
    {

    }

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual override returns (string memory) {
        return "StrategyCurveSETH";
    }

    function balanceOf() public view virtual override returns (uint) {
        return balanceOfWant()
               .add(balanceOfWantInGauge());
    }

    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfWantInGauge() public view returns (uint) {
        return IERC20(gauge).balanceOf(address(this));
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit() internal virtual override {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(gauge, 0);
            IERC20(want).safeApprove(gauge, _want);
            Gauge(gauge).deposit(_want);
        }
    }

    function _claimReward() internal virtual override {
        Mintr(mintr).mint(gauge);
    }

    function _withdrawSome(uint _amount) internal virtual override returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        Gauge(gauge).withdraw(_amount);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
        return _withdrew;
    }

    function _withdrawAll() internal virtual override {
        _withdrawSome(balanceOfWantInGauge());
    }
}
