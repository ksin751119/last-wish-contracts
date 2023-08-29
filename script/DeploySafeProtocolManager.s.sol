// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from 'forge-std/console2.sol';
import {DeployBase} from './DeployBase.s.sol';
import {SafeProtocolManager} from 'safe-protocol/SafeProtocolManager.sol';

contract DeploySafeProtocolManager is DeployBase {
    function _run(
        DeployParameters memory params
    ) internal virtual override isRegistryAddressZero(params.registry) returns (address deployedAddress) {
        deployedAddress = address(new SafeProtocolManager(params.deployer, params.registry));
        console2.log('SafeProtocolManager Deployed:', deployedAddress);
    }
}
