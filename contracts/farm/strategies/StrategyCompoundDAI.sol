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

contract StrategyCompoundDAI is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    address constant public DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // want
    address constant public COMP = address(0xc00e94Cb662C3520282E6f5717214004A7f26888); // reward
    address constant public cDAI = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643); // compound cDAI
    address constant public comptroller = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B); // compoound Comptroller

    /* ========== CONSTRUCTOR ========== */

    constructor(address _controller)
      public
      BaseStrategy(_controller, DAI, COMP)
    {

    }

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual override returns (string memory) {
        return "StrategyCompoundDAI";
    }

    function balanceOf() public view virtual override returns (uint) {
        return balanceOfWant()
               .add(balanceOfCDAI());
    }

    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfCDAI() public view returns (uint) {
        return IERC20(cDAI).balanceOf(address(this)).mul(cERC20(cDAI).exchangeRateStored()).div(1e18);
    }

    function getExchangeRate() public view returns (uint) {
        return cERC20(cDAI).exchangeRateStored();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit() internal virtual override {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(cDAI, 0);
            IERC20(want).safeApprove(cDAI, _want);
            cERC20(cDAI).mint(_want);
        }
    }

    function _claimReward() internal virtual override {
        Comptroller(comptroller).claimComp(address(this));
    }

    function _withdrawSome(uint _amount) internal virtual override returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        cERC20(cDAI).redeemUnderlying(_amount);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
        return _withdrew;
    }

    function _withdrawAll() internal virtual override {
        _withdrawSome(balanceOfCDAI());
    }
}
