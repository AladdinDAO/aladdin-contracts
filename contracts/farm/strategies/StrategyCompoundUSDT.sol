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

contract StrategyCompoundUSDT is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    address constant public USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7); // want
    address constant public COMP = address(0xc00e94Cb662C3520282E6f5717214004A7f26888); // reward
    address constant public cUSDT = address(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9); // compound cUSDT
    address constant public comptroller = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B); // compoound Comptroller

    /* ========== CONSTRUCTOR ========== */

    constructor(address _controller)
      public
      BaseStrategy(_controller, USDT, COMP)
    {

    }

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual override returns (string memory) {
        return "StrategyCompoundUSDT";
    }

    function balanceOf() public view virtual override returns (uint) {
        return balanceOfWant()
               .add(balanceOfCUSDT());
    }

    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfCUSDT() public view returns (uint) {
        return IERC20(cUSDT).balanceOf(address(this)).mul(cERC20(cUSDT).exchangeRateStored()).div(1e18);
    }

    function getExchangeRate() public view returns (uint) {
        return cERC20(cUSDT).exchangeRateStored();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit() internal virtual override {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(cUSDT, 0);
            IERC20(want).safeApprove(cUSDT, _want);
            cERC20(cUSDT).mint(_want);
        }
    }

    function _claimReward() internal virtual override {
        Comptroller(comptroller).claimComp(address(this));
    }

    function _withdrawSome(uint _amount) internal virtual override returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        cERC20(cUSDT).redeemUnderlying(_amount);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
        return _withdrew;
    }

    function _withdrawAll() internal virtual override {
        _withdrawSome(balanceOfCUSDT());
    }
}
