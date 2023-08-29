// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeploySafeProtocolRegistry} from './DeploySafeProtocolRegistry.s.sol';
import {DeploySafeProtocolManager} from './DeploySafeProtocolManager.s.sol';
import {DeployLastWishPlugin} from './DeployLastWishPlugin.s.sol';

contract DeployAll is DeploySafeProtocolRegistry, DeploySafeProtocolManager, DeployLastWishPlugin {
    function _run(
        DeployParameters memory params
    )
        internal
        override(DeploySafeProtocolRegistry, DeploySafeProtocolManager, DeployLastWishPlugin)
        returns (address deployedAddress)
    {
        // registry
        params.registry = DeploySafeProtocolRegistry._run(params);

        // manager
        params.manager = DeploySafeProtocolManager._run(params);

        // plugin
        deployedAddress = DeployLastWishPlugin._run(params);
    }
}
