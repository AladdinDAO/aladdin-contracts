pragma solidity 0.6.12;

interface ITokenMaster {
    function tokenToPid(address _poolToken) external view returns (uint);
    function userBalanceForPool(address _user, address _poolToken) external view returns (uint);
    function deposit(address _token, uint256 _amount) external;
    function pendingALD(address _token, address _user) external view returns (uint256);
}
