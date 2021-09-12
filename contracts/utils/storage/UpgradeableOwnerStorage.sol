// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title UpgradeableOwnerStorage
 * @dev This contract keeps track of the Upgradeable owner
 */
contract UpgradeableOwnerStorage {
  // Owner of the contract
    address private _UpgradeableOwner;

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function UpgradeableOwner() public view returns (address) {
        return _UpgradeableOwner;
    }

    /**
    * @dev Sets the address of the owner
    */
    function setUpgradeableOwner(address newUpgradeableOwner) internal {
        _UpgradeableOwner = newUpgradeableOwner;
    }
}