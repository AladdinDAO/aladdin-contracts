// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IRewardBondDepositor.sol";

contract Keeper is Ownable {
  // The address of reward bond depositor.
  address public immutable depositor;

  // Record whether an address can call bond or not
  mapping(address => bool) public isBondWhitelist;
  // Record whether an address can call rebase or not
  mapping(address => bool) public isRebaseWhitelist;

  // A list of vaults. Push only, beware false-positives.
  address[] public vaults;
  // Record whether an address is vault or not.
  mapping(address => bool) public isVault;

  /// @param _depositor The address of reward bond depositor.
  constructor(address _depositor) {
    depositor = _depositor;
  }

  /// @dev bond ald for a list of vaults.
  /// @param _vaults The address list of vaults.
  function bond(address[] memory _vaults) external {
    require(isBondWhitelist[msg.sender], "Keeper: only bond whitelist");

    for (uint256 i = 0; i < _vaults.length; i++) {
      IRewardBondDepositor(depositor).bond(_vaults[i]);
    }
  }

  /// @dev bond ald for all supported vaults.
  function bondAll() external {
    require(isBondWhitelist[msg.sender], "Keeper: only bond whitelist");

    for (uint256 i = 0; i < vaults.length; i++) {
      address _vault = vaults[i];
      if (isVault[_vault]) {
        IRewardBondDepositor(depositor).bond(_vault);
      }
    }
  }

  /// @dev rebase ald
  function rebase() external {
    require(isRebaseWhitelist[msg.sender], "Keeper: only rebase whitelist");

    IRewardBondDepositor(depositor).rebase();
  }

  /// @dev harvest reward for all supported vaults.
  function harvestAll() external {
    for (uint256 i = 0; i < vaults.length; i++) {
      address _vault = vaults[i];
      if (isVault[_vault]) {
        IVault(_vault).harvest();
      }
    }
  }

  /// @dev update the whitelist who can call bond.
  /// @param _users The list of address.
  /// @param status Whether to add or remove.
  function updateBondWhitelist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      isBondWhitelist[_users[i]] = status;
    }
  }

  /// @dev update the whitelist who can call rebase.
  /// @param _users The list of address.
  /// @param status Whether to add or remove.
  function updateRebaseWhitelist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      isRebaseWhitelist[_users[i]] = status;
    }
  }

  /// @dev update supported vault
  /// @param _vault The address of vault.
  /// @param status Whether it is add or remove vault.
  function updateVault(address _vault, bool status) external onlyOwner {
    if (status) {
      require(!isVault[_vault], "Keeper: already added");
      isVault[_vault] = true;
      if (!_listContainsAddress(vaults, _vault)) {
        vaults.push(_vault);
      }
    } else {
      require(isVault[_vault], "Keeper: already removed");
      isVault[_vault] = false;
    }
  }

  function _listContainsAddress(address[] storage _list, address _item) internal view returns (bool) {
    uint256 length = _list.length;
    for (uint256 i = 0; i < length; i++) {
      if (_list[i] == _item) return true;
    }
    return false;
  }
}
