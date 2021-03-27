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

contract StrategyCompoundUSDC is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    address constant public USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // want
    address constant public COMP = address(0xc00e94Cb662C3520282E6f5717214004A7f26888); // reward
    address constant public cUSDC = address(0x39AA39c021dfbaE8faC545936693aC917d5E7563); // compound cUSDC
    address constant public comptroller = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B); // compoound Comptroller

    /* ========== CONSTRUCTOR ========== */

    constructor(address _controller)
      public
      BaseStrategy(_controller, USDC, COMP)
    {

    }

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual override returns (string memory) {
        return "StrategyCompoundUSDC";
    }

    function balanceOf() public view virtual override returns (uint) {
        return balanceOfWant()
               .add(balanceOfCUSDC());
    }

    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfCUSDC() public view returns (uint) {
        return IERC20(cUSDC).balanceOf(address(this)).mul(cERC20(cUSDC).exchangeRateStored()).div(1e18);
    }

    function getExchangeRate() public view returns (uint) {
        return cERC20(cUSDC).exchangeRateStored();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit() internal virtual override {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(cUSDC, 0);
            IERC20(want).safeApprove(cUSDC, _want);
            cERC20(cUSDC).mint(_want);
        }
    }

    function _claimReward() internal virtual override {
        Comptroller(comptroller).claimComp(address(this));
    }

    function _withdrawSome(uint _amount) internal virtual override returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        cERC20(cUSDC).redeemUnderlying(_amount);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
        return _withdrew;
    }

    function _withdrawAll() internal virtual override {
        _withdrawSome(balanceOfCUSDC());
    }
}
