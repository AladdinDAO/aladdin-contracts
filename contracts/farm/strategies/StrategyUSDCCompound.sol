pragma solidity 0.6.12;

import "./BaseStrategy.sol";

interface cERC20 {
    function mint(uint256 mintAmount) external returns ( uint256 );
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function exchangeRateStored() external view returns (uint);
}

contract StrategyUSDCCompound is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    address constant public USDC = address(0xb7a4F3E9097C08dA09517b5aB877F7a917224ede); // want
    address constant public COMP = address(0x61460874a7196d6a22D1eE4922473664b3E95270); // reward
    address constant public cUSDC = address(0x4a92E71227D294F041BD82dd8f78591B75140d63); // compound cUSDC

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
        // Compound auto distributes COMP rewards on deposit and withdraw, no need to claim
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
