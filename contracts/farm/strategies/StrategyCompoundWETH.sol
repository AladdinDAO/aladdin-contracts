pragma solidity 0.6.12;

import "./BaseStrategy.sol";

interface cEther {
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function exchangeRateStored() external view returns (uint);
}

interface Comptroller {
    function claimComp(address holder) external;
}

interface WrappedEther {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract StrategyCompoundWETH is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    address constant public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // want
    address constant public COMP = address(0xc00e94Cb662C3520282E6f5717214004A7f26888); // reward
    address constant public cETH = address(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5); // compound cETH
    address constant public comptroller = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B); // compoound Comptroller

    /* ========== CONSTRUCTOR ========== */

    constructor(address _controller)
      public
      BaseStrategy(_controller, WETH, COMP)
    {

    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    // make strategy receivable of ETH for WETH <-> ETH conversion
    receive() external payable{}

    /* ========== VIEW FUNCTIONS ========== */

    function getName() external pure virtual override returns (string memory) {
        return "StrategyCompoundWETH";
    }

    function balanceOf() public view virtual override returns (uint) {
        return balanceOfWant()
               .add(balanceOfETH())
               .add(balanceOfCETH());
    }

    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    // should always be zero
    function balanceOfETH() public view returns (uint) {
        address(this).balance;
    }

    function balanceOfCETH() public view returns (uint) {
        return IERC20(cETH).balanceOf(address(this)).mul(cEther(cETH).exchangeRateStored()).div(1e18);
    }

    function getExchangeRate() public view returns (uint) {
        return cEther(cETH).exchangeRateStored();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit() internal virtual override {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            // convert to ETH
            WrappedEther(WETH).withdraw(_want);
            // deposit ETH to Compound
            (bool sent, ) = address(cETH).call{value: _want}("");
            require(sent, "Failed to send Ether to cETH");
        }
    }

    function _claimReward() internal virtual override {
        Comptroller(comptroller).claimComp(address(this));
    }

    function _withdrawSome(uint _amount) internal virtual override returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        uint rcode = cEther(cETH).redeemUnderlying(_amount);
        require(rcode == 0, "Failed to redeem underlying from Compound");

        // wrap to WETH
        (bool sent, ) = address(WETH).call{value: _amount}("");
        require(sent, "Failed to send Ether to WETH");

        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);

        return _withdrew;
    }

    function _withdrawAll() internal virtual override {
        _withdrawSome(balanceOfCETH());
    }
}
