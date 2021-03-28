pragma solidity 0.6.12;

import "./BaseStrategy.sol";

interface Gauge {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
}

interface Mintr {
    function mint(address _gauge) external;
}

contract StrategyCurveRenWBTC is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address constant public crvRenWBTC = address(0x49849C98ae39Fff122806C06791Fa73784FB3675); // want
    address constant public CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // reward
    address constant public gauge = address(0xB1F2cdeC61db658F091671F5f199635aEF202CAC);
    address constant public mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _controller)
      public
      BaseStrategy(_controller, crvRenWBTC, CRV)
    {

    }

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual override returns (string memory) {
        return "StrategyCurveRenWBTC";
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
