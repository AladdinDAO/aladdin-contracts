pragma solidity 0.6.12;

interface ITokenLocker {
    function lock(uint _amount, address _recipient) external;
}
