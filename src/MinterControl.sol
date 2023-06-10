pragma solidity >=0.8.0;

import {Pausable} from "../lib/openzeppelin-contracts/contracts/security/Pausable.sol";

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MinterControl is Ownable {
    constructor() {}

    mapping(address => bool) public allowedMinters;
    address[] public minterAddresses;

    modifier onlyMinters() {
        require(allowedMinters[msg.sender], "Not on the allow list");
        _;
    }

    /// @dev checks if it is on the minterAddresses array

    function isMinter(address minter) public view returns (bool) {
        for (uint i = 0; i < minterAddresses.length; i++) {
            if (minterAddresses[i] == minter) {
                return true;
            }
        }
        return false;
    }

    // To add a minter, the address cannot be on the list (array) of minterAddress
    // If the minter is not on the allowedMinters list but is on minterAddresses it means it has been disabled
    function addMinter(address minter) public onlyOwner returns (bool success) {
        require(minter != owner(), "You cannot add the owner!");
        require(minter != address(0), "Zero address!");
        require(!isMinter(minter), "Minter already added");
        allowedMinters[minter] = true;
        minterAddresses.push(minter);
        success = true;
    }

    ///@dev To remove a minter, it has to be on the list (array) of minterAddress
    // Once a minter is removed, it is removed from both minterAddresses and marked false on allowedMinters
    function removeMinter(
        address minter
    ) public onlyOwner returns (bool success) {
        require(minter != address(0), "Zero address!");
        require(minter != owner(), "You cannot remove the owner!");
        require(isMinter(minter), "Address not on list of minter addresses!");
        delete allowedMinters[minter];

        for (uint256 i = 0; i < minterAddresses.length; i++) {
            // if the programme finds a slot in the array whose entry is the minter
            // it replaces it with the last element in the array
            if (minterAddresses[i] == minter) {
                minterAddresses[i] = minterAddresses[
                    minterAddresses.length - 1
                ];
                minterAddresses.pop();
                break;
            }
        }
        success = true;
    }

    ///@dev  to enable a minter, the address must be already added to minterAddress
    // if the minter is already enabled, the function enables it again
    function enableMinter(address minter) public onlyOwner returns (bool) {
        require(isMinter(minter), "Address is not a minter!");
        allowedMinters[minter] = true;
        return allowedMinters[minter];
    }

    ///@dev  to disable a minter, the address must be already added to minterAddress
    // if the minter is already disabled, the function disables it again
    function disableMinter(address minter) public onlyOwner returns (bool) {
        require(isMinter(minter), "Address is not a minter!");
        allowedMinters[minter] = false;
        return allowedMinters[minter];
    }

    function enableAllMinters() public onlyOwner returns (bool success) {
        success = true;
        for (uint256 i = 0; i < minterAddresses.length; i++) {
            allowedMinters[minterAddresses[i]] = true;
            success = success && allowedMinters[minterAddresses[i]];
        }
        return success;
    }

    function disableAllMinters() public onlyOwner returns (bool success) {
        success = true;

        for (uint256 i = 0; i < minterAddresses.length; i++) {
            allowedMinters[minterAddresses[i]] = false;
            success = success && !allowedMinters[minterAddresses[i]];
        }
        return success;
    }
}
