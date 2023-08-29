// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IGnosisSafe, Enum} from './IGnosisSafe.sol';
import {LibUniqueAddressList} from './libraries/LibUniqueAddressList.sol';

contract LastWishModule {
    using LibUniqueAddressList for LibUniqueAddressList.List;
    string public constant NAME = 'LastWish Module';
    string public constant VERSION = '0.1.0';

    // Safe -> Heir
    mapping(address => Heir) public heirs;
    mapping(address => LibUniqueAddressList.List) internal _heirSafeList;

    struct Heir {
        address recipient;
        uint256 timeLock;
        uint256 inheritingStart;
    }

    event SetHeir(address indexed safe, address recipient, uint256 timeLock);
    event ApplyForSafeTransfer(address indexed safe, address recipient, uint256 timeLock, uint256 inheritingStart);
    event ClaimSafe(address indexed safe, address recipient);
    event RejectSafeTransfer(address indexed safe, address recipient);

    function getHeirSafes(address heir) external view returns (address[] memory) {
        return _heirSafeList[heir]._get();
    }

    function setHeir(address recipient_, uint256 timeLock_) public {
        Heir memory heir = heirs[msg.sender];
        if (heir.recipient != address(0)) {
            _heirSafeList[heir.recipient]._remove(address(msg.sender));
        }

        heirs[msg.sender] = Heir(recipient_, timeLock_, 0);
        _heirSafeList[recipient_]._pushBack(msg.sender);
        emit SetHeir(msg.sender, recipient_, timeLock_);
    }

    function applyForSafeTransfer(address safe) public {
        Heir memory heir = heirs[safe];
        require(heir.recipient != address(0), 'Not set heir yet');
        require(heir.inheritingStart == 0, 'Have been inherited');
        require(heir.recipient == msg.sender, 'Not safe heir');
        require(_heirSafeList[msg.sender]._exist(safe), 'Not in heir safe list');

        heirs[safe].inheritingStart = block.timestamp;
        emit ApplyForSafeTransfer(safe, heir.recipient, heir.timeLock, heir.inheritingStart);
    }

    function claimSafe(address safe) public {
        Heir memory heir = heirs[safe];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart > 0, 'not inherit yet');
        require(block.timestamp >= heir.inheritingStart + heir.timeLock, 'time lock');
        bytes memory data = abi.encodeWithSelector(IGnosisSafe.addOwnerWithThreshold.selector, heir.recipient, 1);
        require(
            IGnosisSafe(safe).execTransactionFromModule(safe, 0, data, Enum.Operation.Call),
            'Could not execute ether transfer'
        );

        // Reset safe information
        delete heirs[safe];
        _heirSafeList[heir.recipient]._remove(safe);
        emit ClaimSafe(safe, heir.recipient);
    }

    function rejectSafeTransfer() public {
        Heir memory heir = heirs[msg.sender];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart > 0, 'not inherit yet');

        delete heirs[msg.sender];
        _heirSafeList[heir.recipient]._remove(msg.sender);
        emit RejectSafeTransfer(msg.sender, heir.recipient);
    }
}
