//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Testing utilities */
import {Test} from 'forge-std/Test.sol';

import {SafeProxyFactory} from 'safe-contracts/proxies/SafeProxyFactory.sol';
import {SafeProxy} from 'safe-contracts/proxies/SafeProxy.sol';
import {Safe} from 'safe-contracts/Safe.sol';
import {ISafe} from 'safe-protocol/interfaces/Accounts.sol';
import {SafeProtocolRegistry} from 'safe-protocol/SafeProtocolRegistry.sol';
import {SafeProtocolManager} from 'safe-protocol/SafeProtocolManager.sol';
import {SafeTransaction, SafeProtocolAction} from 'safe-protocol/DataTypes.sol';
import {Enum} from 'safe-protocol/common/Enum.sol';
import {ERC20, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {OwnerManager} from 'safe-contracts/base/OwnerManager.sol';

import {PluginMetadata} from '../src/PluginBase.sol';
import {LastWishPlugin} from '../src/LastWishPlugin.sol';

import {console2} from 'forge-std/console2.sol';

// NOTE: safe error codes: https://github.com/safe-global/safe-contracts/blob/main/docs/error_codes.md

contract LastWishPluginTest is Test {
    // ecosystem agents
    address public owner;
    address public safeOwner;
    address public heir;
    SafeProxy public s;

    SafeProtocolRegistry public registry;
    SafeProtocolManager public manager;
    LastWishPlugin public plugin;
    Safe public safeProxy;

    function setUp() public {
        owner = makeAddr('owner');
        safeOwner = makeAddr('safeOwner');
        heir = makeAddr('owner');

        // safe-protocol sc
        registry = new SafeProtocolRegistry(owner);
        manager = new SafeProtocolManager(owner, address(registry));
        plugin = new LastWishPlugin();

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

        // Enable manager module
        vm.prank(address(safeProxy));
        safeProxy.enableModule(address(manager));
        assertEq(safeProxy.isModuleEnabled(address(manager)), true);

        // Register plugin to registry
        vm.prank(owner);
        registry.addIntegration(address(plugin), Enum.IntegrationType.Plugin);

        // Enable plug
        vm.prank(address(safeProxy));
        manager.enablePlugin(address(plugin), true);
        assertEq(manager.isPluginEnabled(address(safeProxy), address(plugin)), true);
    }

    function testClaimSafe() public {
        uint256 timeLock = 5 minutes;

        // Set Heir
        vm.prank(address(safeProxy));
        plugin.setHeir(heir, timeLock);

        // Apply safe transfer
        vm.prank(heir);
        plugin.applyForSafeTransfer(address(safeProxy));

        // Claim safe
        assertEq(OwnerManager(address(safeProxy)).isOwner(heir), false);
        vm.warp(block.timestamp + timeLock + 1);
        vm.prank(heir);
        plugin.claimSafe(manager, address(safeProxy));

        // Verify
        assertEq(OwnerManager(address(safeProxy)).isOwner(heir), true);
    }
}
