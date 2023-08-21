// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IGnosisSafe, Enum} from './IGnosisSafe.sol';

contract LastWishModule {
    string public constant NAME = 'LastWish Module';
    string public constant VERSION = '0.1.0';

    // Safe -> Heir
    mapping(address => Heir) public heirs;

    struct Heir {
        address recipient;
        uint256 timeLock;
        uint256 inheritingStart;
    }

    event SetHeir(address indexed safe, address recipient, uint256 timeLock);
    event TransferSafe(address indexed safe, address recipient, uint256 timeLock, uint256 inheritingStart);
    event ClaimSafe(address indexed safe, address recipient);
    event RejectSafe(address indexed safe, address recipient);

    function setHeir(address recipient_, uint256 timeLock_) public {
        heirs[msg.sender] = Heir(recipient_, timeLock_, 0);
        emit SetHeir(msg.sender, recipient_, timeLock_);
    }

    function transferSafe() public {
        Heir memory heir = heirs[msg.sender];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart == 0, 'have been inherited');
        heir.inheritingStart = block.timestamp;
        heirs[msg.sender] = heir;
        emit TransferSafe(msg.sender, heir.recipient, heir.timeLock, heir.inheritingStart);
    }

    function claimSafe(IGnosisSafe safe) public {
        Heir memory heir = heirs[address(safe)];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart > 0, 'not inherit yet');
        require(block.timestamp >= heir.inheritingStart + heir.timeLock, 'time lock');
        bytes memory data = abi.encodeWithSelector(IGnosisSafe.addOwnerWithThreshold.selector, heir.recipient, 1);
        require(
            safe.execTransactionFromModule(address(safe), 0, data, Enum.Operation.Call),
            'Could not execute ether transfer'
        );

        // Reset safe information
        delete heirs[address(safe)];
        emit ClaimSafe(address(safe), heir.recipient);
    }

    function rejectSafe() public {
        Heir memory heir = heirs[msg.sender];
        require(heir.recipient != address(0), 'not set heir');
        require(heir.inheritingStart > 0, 'not inherit yet');
        emit RejectSafe(msg.sender, heir.recipient);
        delete heirs[msg.sender];
    }
}
