pragma solidity 0.6.12;

import "./BaseStrategy.sol";

interface cERC20 {
    function mint(uint256 mintAmount) external returns ( uint256 );
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function exchangeRateStored() external view returns (uint);
}

interface Comptroller {
    function claimComp(address holder) external;
}

contract StrategyCompoundWBTC is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    address constant public WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // want
    address constant public COMP = address(0xc00e94Cb662C3520282E6f5717214004A7f26888); // reward
    address constant public cWBTC = address(0xccF4429DB6322D5C611ee964527D42E5d685DD6a); // compound cWBTC
    address constant public comptroller = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B); // compoound Comptroller

    /* ========== CONSTRUCTOR ========== */

    constructor(address _controller)
      public
      BaseStrategy(_controller, WBTC, COMP)
    {

    }

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual override returns (string memory) {
        return "StrategyCompoundWBTC";
    }

    function balanceOf() public view virtual override returns (uint) {
        return balanceOfWant()
               .add(balanceOfCWBTC());
    }

    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfCWBTC() public view returns (uint) {
        return IERC20(cWBTC).balanceOf(address(this)).mul(cERC20(cWBTC).exchangeRateStored()).div(1e18);
    }

    function getExchangeRate() public view returns (uint) {
        return cERC20(cWBTC).exchangeRateStored();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit() internal virtual override {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(cWBTC, 0);
            IERC20(want).safeApprove(cWBTC, _want);
            cERC20(cWBTC).mint(_want);
        }
    }

    function _claimReward() internal virtual override {
        Comptroller(comptroller).claimComp(address(this));
    }

    function _withdrawSome(uint _amount) internal virtual override returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        cERC20(cWBTC).redeemUnderlying(_amount);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
        return _withdrew;
    }

    function _withdrawAll() internal virtual override {
        _withdrawSome(balanceOfCWBTC());
    }
}
