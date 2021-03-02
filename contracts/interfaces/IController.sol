pragma solidity 0.6.12;

interface IController {
    function withdraw(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function farm(address, uint) external;
    function harvest(address) external;
}
