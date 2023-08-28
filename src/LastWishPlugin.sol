// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import {IGnosisSafe} from './IGnosisSafe.sol';
import {ISafe} from 'safe-protocol/interfaces/Accounts.sol';
import {BasePluginWithEventMetadata, PluginMetadata} from './PluginBase.sol';
import {ISafeProtocolManager} from 'safe-protocol/interfaces/Manager.sol';
import {SafeTransaction, SafeProtocolAction} from 'safe-protocol/DataTypes.sol';

import {OwnerManager} from 'safe-contracts/base/OwnerManager.sol';

contract LastWishPlugin is BasePluginWithEventMetadata {
    // string public constant name = 'LastWish Plugin';
    // string public constant version = '0.1.0';

    // Safe -> Heir
    mapping(address => Heir) public heirs;

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
                version: '0.1.0',
                requiresRootAccess: false,
                iconUrl: '',
                appUrl: ''
            })
        )
    {}

    function setHeir(address recipient_, uint256 timeLock_) public {
        heirs[msg.sender] = Heir(recipient_, timeLock_, 0);
        emit SetHeir(msg.sender, recipient_, timeLock_);
    }

    function applyForSafeTransfer(ISafe safe) public {
        Heir memory heir = heirs[address(safe)];
        require(heir.recipient != address(0), 'not set heir yet');
        require(heir.inheritingStart == 0, 'have been inherited');
        require(heir.recipient == msg.sender, 'Not safe heir');
        heir.inheritingStart = block.timestamp;
        emit ApplyForSafeTransfer(msg.sender, heir.recipient, heir.timeLock, heir.inheritingStart);
    }

    function claimSafe(ISafeProtocolManager manager, ISafe safe) public {
        // Authorize heir and information
        Heir memory heir = heirs[address(safe)];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart > 0, 'not inherit yet');
        require(block.timestamp >= heir.inheritingStart + heir.timeLock, 'time lock');

        // Prepare safe transaction
        SafeProtocolAction[] memory transactions = new SafeProtocolAction[](1);
        transactions[0] = SafeProtocolAction({
            to: payable(address(safe)),
            value: 0,
            data: abi.encodeWithSelector(OwnerManager.addOwnerWithThreshold.selector, heir.recipient, 1)
        });

        SafeTransaction memory transaction = SafeTransaction({
            actions: transactions,
            nonce: 0,
            metadataHash: bytes32(0)
        });
        ISafeProtocolManager(manager).executeTransaction(safe, transaction);

        // Reset safe information
        delete heirs[address(safe)];
        emit ClaimSafe(address(safe), heir.recipient);
    }

    function rejectSafeTransfer() public {
        Heir memory heir = heirs[msg.sender];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart > 0, 'not inherit yet');
        emit RejectSafeTransfer(msg.sender, heir.recipient);
        delete heirs[msg.sender];
    }
}
