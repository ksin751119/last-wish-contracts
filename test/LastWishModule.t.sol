//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Testing utilities */
import {Test} from 'forge-std/Test.sol';

import {SafeProxyFactory} from 'safe-contracts/proxies/SafeProxyFactory.sol';
import {SafeProxy} from 'safe-contracts/proxies/SafeProxy.sol';
import {Safe} from 'safe-contracts/Safe.sol';
import {Enum} from 'safe-protocol/common/Enum.sol';
import {OwnerManager} from 'safe-contracts/base/OwnerManager.sol';
import {LastWishModule} from '../src/LastWishModule.sol';

import 'forge-std/console.sol';

contract LastWishmoduleTest is Test {
    uint256 private constant _SET_TIME_LOCK = 5 minutes;

    address public owner;
    address public safeOwner;
    address public safeMock;
    address public heir;
    SafeProxy public s;

    LastWishModule public module;
    Safe public safeProxy;

    event SetHeir(address indexed safe, address recipient, uint256 timeLock);
    event ApplyForSafeTransfer(address indexed safe, address recipient, uint256 timeLock, uint256 inheritingStart);
    event ClaimSafe(address indexed safe, address recipient);
    event RejectSafeTransfer(address indexed safe, address recipient);

    function setUp() public {
        owner = makeAddr('owner');
        safeOwner = makeAddr('safeOwner');
        safeMock = makeAddr('safeMock');
        heir = makeAddr('owner');

        // safe-protocol sc
        module = new LastWishModule();

        // Initialize Safe
        SafeProxyFactory safeFactory = new SafeProxyFactory();
        Safe safe = new Safe(); // singleton implementation

        address[] memory safeOwners = new address[](1);
        safeOwners[0] = safeOwner;
        bytes memory initializer = abi.encodeWithSelector(
            Safe.setup.selector,
            safeOwners, // owners
            1, // threshold
            address(0), // to
            abi.encode(0), // data
            address(0), // fallbackHandler
            address(0), // paymentToken
            0, // payment
            payable(address(0)) // paymentReceiver
        );
        s = safeFactory.createProxyWithNonce(address(safe), initializer, 50);
        safeProxy = Safe(payable(address(s)));

        // Enable module
        vm.prank(address(safeProxy));
        safeProxy.enableModule(address(module));
        assertTrue(safeProxy.isModuleEnabled(address(module)));
    }

    function testGetHeirSafeList() public {
        address[] memory safes = module.getHeirSafes(heir);
        assertEq(safes.length, 0);

        vm.prank(address(safeProxy));
        module.setHeir(heir, _SET_TIME_LOCK);

        // Verify
        safes = module.getHeirSafes(heir);
        assertEq(safes.length, 1);
        assertEq(safes[0], address(safeProxy));

        vm.prank(safeMock);
        module.setHeir(heir, _SET_TIME_LOCK);

        safes = module.getHeirSafes(heir);
        assertEq(safes.length, 2);
        assertEq(safes[0], address(safeProxy));
        assertEq(safes[1], safeMock);
    }

    function testSetHeir() public {
        (address recipient, uint256 timeLock, uint256 inheritingStart) = module.heirs(address(safeProxy));
        assertEq(recipient, address(0));
        assertEq(timeLock, 0);
        assertEq(inheritingStart, 0);

        vm.expectEmit(true, true, true, false);
        emit SetHeir(address(safeProxy), heir, _SET_TIME_LOCK);
        vm.prank(address(safeProxy));
        module.setHeir(heir, _SET_TIME_LOCK);

        // Verify
        (recipient, timeLock, inheritingStart) = module.heirs(address(safeProxy));
        assertEq(recipient, heir);
        assertEq(timeLock, _SET_TIME_LOCK);
        assertEq(inheritingStart, 0);
    }

    // TODO: testSetHeirMultipleTimes

    function testApplyForSafeTransfer() public {
        // Set Heir
        vm.prank(address(safeProxy));
        module.setHeir(heir, _SET_TIME_LOCK);

        // Apply safe transfer
        vm.expectEmit(true, true, true, false);
        emit ApplyForSafeTransfer(address(safeProxy), heir, _SET_TIME_LOCK, block.timestamp);
        vm.prank(heir);
        module.applyForSafeTransfer(address(safeProxy));

        // Verify
        (, , uint256 inheritingStart) = module.heirs(address(safeProxy));
        assertGt(inheritingStart, 0);
    }

    // TODO: testCannotApplyBeforeHeirNotSet
    // TODO: testCannotApplyTwice
    // TODO: testCannotApplyByInvalidHeir

    function testClaimSafe() public {
        // Set Heir
        vm.prank(address(safeProxy));
        module.setHeir(heir, _SET_TIME_LOCK);

        // Apply safe transfer
        vm.prank(heir);
        module.applyForSafeTransfer(address(safeProxy));

        // Claim safe
        assertEq(OwnerManager(address(safeProxy)).isOwner(heir), false);
        vm.warp(block.timestamp + _SET_TIME_LOCK + 1);
        vm.expectEmit(true, true, false, false);
        emit ClaimSafe(address(safeProxy), heir);
        vm.prank(heir);
        module.claimSafe(address(safeProxy));

        // Verify
        assertTrue(OwnerManager(address(safeProxy)).isOwner(heir));
    }

    // TODO: testCannotClaimBeforeHeirNotSet
    // TODO: testCannotClaimBeforeNotInherit
    // TODO: testCannotClaimBeforeTimeLockAchieved

    function testRejectSafeTransfer() public {
        // Set Heir
        vm.prank(address(safeProxy));
        module.setHeir(heir, _SET_TIME_LOCK);

        // Apply safe transfer
        vm.prank(heir);
        module.applyForSafeTransfer(address(safeProxy));

        // Claim safe
        assertEq(OwnerManager(address(safeProxy)).isOwner(heir), false);
        vm.warp(block.timestamp + _SET_TIME_LOCK + 1);
        vm.expectEmit(true, true, false, false);
        emit RejectSafeTransfer(address(safeProxy), heir);
        vm.prank(address(safeProxy));
        module.rejectSafeTransfer();

        // Verify
        (address recipient, uint256 timeLock, uint256 inheritingStart) = module.heirs(address(safeProxy));
        assertEq(recipient, address(0));
        assertEq(timeLock, 0);
        assertEq(inheritingStart, 0);

        address[] memory safes = module.getHeirSafes(heir);
        assertEq(safes.length, 0);
    }

    // TODO: testCannotRejectBeforeHeirNotSet
    // TODO: testCannotRejectBeforeNotInherit
}
