// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from 'safe-protocol/interfaces/Accounts.sol';
import {BasePluginWithEventMetadata, PluginMetadata} from './PluginBase.sol';
import {ISafeProtocolManager} from 'safe-protocol/interfaces/Manager.sol';
import {SafeTransaction, SafeProtocolAction} from 'safe-protocol/DataTypes.sol';
import {OwnerManager} from 'safe-contracts/base/OwnerManager.sol';
import {LibUniqueAddressList} from './libraries/LibUniqueAddressList.sol';

contract LastWishPlugin is BasePluginWithEventMetadata {
    using LibUniqueAddressList for LibUniqueAddressList.List;

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

    constructor()
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: 'LastWish Plugin',
                version: '0.0.1',
                requiresRootAccess: true,
                iconUrl: '',
                appUrl: ''
            })
        )
    {}

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
        require(_heirSafeList[heir.recipient]._exist(safe), 'Not in heir safe list');

        heirs[safe].inheritingStart = block.timestamp;
        emit ApplyForSafeTransfer(safe, heir.recipient, heir.timeLock, heir.inheritingStart);
    }

    function claimSafe(ISafeProtocolManager manager, address safe) public {
        // Authorize heir and information
        Heir memory heir = heirs[address(safe)];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart > 0, 'not inherit yet');
        require(block.timestamp >= heir.inheritingStart + heir.timeLock, 'time lock');

        // Prepare safe transaction
        SafeProtocolAction[] memory transactions = new SafeProtocolAction[](1);
        transactions[0] = SafeProtocolAction({
            to: payable(safe),
            value: 0,
            data: abi.encodeWithSelector(OwnerManager.addOwnerWithThreshold.selector, heir.recipient, 1)
        });

        SafeTransaction memory transaction = SafeTransaction({
            actions: transactions,
            nonce: 0,
            metadataHash: bytes32(0)
        });
        ISafeProtocolManager(manager).executeTransaction(ISafe(safe), transaction);

        // Reset safe information
        delete heirs[address(safe)];
        _heirSafeList[heir.recipient]._remove(address(safe));
        emit ClaimSafe(address(safe), heir.recipient);
    }

    function rejectSafeTransfer() public {
        Heir memory heir = heirs[msg.sender];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart > 0, 'not inherit yet');

        // Reset safe information
        delete heirs[msg.sender];
        _heirSafeList[heir.recipient]._remove(msg.sender);

        emit RejectSafeTransfer(msg.sender, heir.recipient);
    }
}
