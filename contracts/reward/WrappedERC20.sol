pragma solidity 0.6.12;

import "../common/ERC20.sol";
import "../common/IERC20.sol";
import "../common/SafeERC20.sol";
import "../interfaces/IWrappedERC20.sol";

// Standard ERC20 token that wraps an underlying ERC20
contract WrappedERC20 is IWrappedERC20, ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public underlying;

    constructor (address _underlying, string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {
        _setupDecimals(ERC20(_underlying).decimals());
        underlying = IERC20(_underlying);
    }

    function wrap(address _to, uint _amount) external override {
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(_to, _amount);
    }

    function unwrap(address _to, uint _amount) external override {
        _burn(msg.sender, _amount);
        underlying.safeTransfer(_to, _amount);
    }
}
