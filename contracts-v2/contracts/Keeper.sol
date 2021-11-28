// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IRewardBondDepositor.sol";

contract Keeper is Ownable {
  address public immutable depositor;

  // Record whether an address can call bond or not
  mapping(address => bool) public isBondWhitelist;
  // Record whether an address can call rebase or not
  mapping(address => bool) public isRebaseWhitelist;

  // A list of vaults. Push only, beware false-positives.
  address[] public vaults;
  // Record whether an address is vault or not.
  mapping(address => bool) public isVault;

  constructor(address _depositor) {
    depositor = _depositor;
  }

  function bond(address[] memory _vaults) external {
    require(isBondWhitelist[msg.sender], "Keeper: only bond whitelist");

    for (uint256 i = 0; i < _vaults.length; i++) {
      IRewardBondDepositor(depositor).bond(_vaults[i]);
    }
  }

  function bondAll() external {
    require(isBondWhitelist[msg.sender], "Keeper: only bond whitelist");

    for (uint256 i = 0; i < vaults.length; i++) {
      address _vault = vaults[i];
      if (isVault[_vault]) {
        IRewardBondDepositor(depositor).bond(_vault);
      }
    }
  }

  function rebase() external {
    require(isRebaseWhitelist[msg.sender], "Keeper: only rebase whitelist");

    IRewardBondDepositor(depositor).rebase();
  }

  function harvestAll() external {
    for (uint256 i = 0; i < vaults.length; i++) {
      address _vault = vaults[i];
      if (isVault[_vault]) {
        IVault(_vault).harvest();
      }
    }
  }

  function updateBondWhitelist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      isBondWhitelist[_users[i]] = status;
    }
  }

  function updateRebaseWhitelist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      isRebaseWhitelist[_users[i]] = status;
    }
  }

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
