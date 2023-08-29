// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from 'forge-std/console2.sol';
import {DeployBase} from './DeployBase.s.sol';
import {SafeProtocolRegistry} from 'safe-protocol/SafeProtocolRegistry.sol';

contract DeploySafeProtocolRegistry is DeployBase {
    function _run(DeployParameters memory params) internal virtual override returns (address deployedAddress) {
        deployedAddress = address(new SafeProtocolRegistry(params.deployer));
        console2.log('SafeProtocolRegistry Deployed:', deployedAddress);
    }
}
