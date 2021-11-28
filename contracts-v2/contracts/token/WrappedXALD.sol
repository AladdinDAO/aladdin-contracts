// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IWXALD.sol";
import "../interfaces/IXALD.sol";

contract WrappedXALD is ERC20, IWXALD {
  IXALD public xALD;

  /**
   * @param _xALD address of the xALD token to wrap
   */
  constructor(IXALD _xALD) ERC20("Wrapped Staked ALD Token", "wxALD") {
    xALD = _xALD;
  }

  /**
   * @dev Wrap xALD to wxALD
   * @param _xALDAmount amount of xALD to wrap in exchange for wxALD
   * @return Amount of wxALD user receives after wrap
   */
  function wrap(uint256 _xALDAmount) external override returns (uint256) {
    require(_xALDAmount > 0, "wxALD: can't wrap zero xALD");
    xALD.transferFrom(msg.sender, address(this), _xALDAmount);
    uint256 wxALDAmount = xALD.getSharesByALD(_xALDAmount);
    _mint(msg.sender, wxALDAmount);
    return wxALDAmount;
  }

  /**
   * @notice Unwrap wxALD to xALD
   * @param _wxALDAmount amount of wxALD to uwrap in exchange for xALD
   * @return Amount of xALD user receives after unwrap
   */
  function unwrap(uint256 _wxALDAmount) external override returns (uint256) {
    require(_wxALDAmount > 0, "wxALD: zero amount unwrap not allowed");
    _burn(msg.sender, _wxALDAmount);
    uint256 xALDAmount = xALD.getALDByShares(_wxALDAmount);
    xALD.transfer(msg.sender, xALDAmount);
    return xALDAmount;
  }

  /**
   * @notice Get amount of wxALD for a given amount of xALD
   * @param _xALDAmount amount of xALD
   * @return Amount of wxALD for a given xALD amount
   */
  function XALDToWrappedXALD(uint256 _xALDAmount) external view returns (uint256) {
    return xALD.getSharesByALD(_xALDAmount);
  }

  /**
   * @notice Get amount of xALD for a given amount of wxALD
   * @param _wxALDAmount amount of wxALD
   * @return Amount of xALD for a given wxALD amount
   */
  function wrappedXALDToXALD(uint256 _wxALDAmount) external view override returns (uint256) {
    return xALD.getALDByShares(_wxALDAmount);
  }

  /**
   * @dev Get amount of xALD for a one wxALD
   * @return Amount of xALD for 1 wxALD
   */
  function XALDPerToken() external view returns (uint256) {
    return xALD.getALDByShares(1 ether);
  }

  /**
   * @dev Get amount of wxALD for a one xALD
   * @return Amount of wxALD for a 1 xALD
   */
  function tokensPerXALD() external view returns (uint256) {
    return xALD.getSharesByALD(1 ether);
  }
}
