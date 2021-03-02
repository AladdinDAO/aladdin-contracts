pragma solidity 0.6.12;

interface IStrategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(address) external;
    function withdraw(uint) external;
    function withdrawAll() external returns (uint);
    function harvest() external;
    function balanceOf() external view returns (uint);
}
