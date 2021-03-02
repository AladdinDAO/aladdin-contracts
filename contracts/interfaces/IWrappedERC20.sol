pragma solidity 0.6.12;

interface IWrappedERC20 {
    function wrap(address _to, uint _amount) external;
    function unwrap(address _to, uint _amount) external;
}
