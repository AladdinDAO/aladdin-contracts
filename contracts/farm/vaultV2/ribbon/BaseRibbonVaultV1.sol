// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../BaseVaultV2.sol";

interface IRibbonThetaVault {
  function depositETH() external payable;

  function deposit(uint256 amount) external;

  function withdrawETH(uint256 share) external;

  function withdraw(uint256 share) external;

  function totalBalance() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

contract BaseRibbonVaultV1 is BaseVaultV2 {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  IRibbonThetaVault public immutable ribbonThetaVault;

  constructor(
    address _weth,
    address _token,
    address _rewardToken,
    address _treasury,
    address _tokenMaster,
    IRibbonThetaVault _ribbonThetaVault
  ) public BaseVaultV2(_weth, _token, _rewardToken, _treasury, _tokenMaster) {
    ribbonThetaVault = _ribbonThetaVault;
  }

  // Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal override {
    IERC20 _token = token;
    uint256 amount = _token.balanceOf(address(this));
    if (amount > 0) {
      IRibbonThetaVault _ribbonThetaVault = ribbonThetaVault;
      _token.safeApprove(address(_ribbonThetaVault), amount);
      _ribbonThetaVault.deposit(amount);
    }
  }

  // Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal override {
    IRibbonThetaVault _ribbonThetaVault = ribbonThetaVault; // gas saving
    uint256 total = _ribbonThetaVault.totalBalance();
    uint256 shareSupply = _ribbonThetaVault.totalSupply();
    uint256 _share = _amount.mul(shareSupply).div(total);

    _ribbonThetaVault.withdraw(_share);
  }

  // Harvest rewards from strategy into vault
  function _harvest() internal override {}

  // Balance of deposit token in underlying strategy
  function _balanceOf() internal view override returns (uint256) {
    IRibbonThetaVault _ribbonThetaVault = ribbonThetaVault; // gas saving
    uint256 total = _ribbonThetaVault.totalBalance();
    uint256 shareSupply = _ribbonThetaVault.totalSupply();
    uint256 share = _ribbonThetaVault.balanceOf(address(this));
    return share.mul(total).div(shareSupply);
  }
}
