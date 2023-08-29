// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from 'forge-std/console2.sol';
import {DeployBase} from './DeployBase.s.sol';
import {LastWishPlugin} from '../src/LastWishPlugin.sol';

contract DeployLastWishPlugin is DeployBase {
    function _run(DeployParameters memory) internal virtual override returns (address deployedAddress) {
        deployedAddress = address(new LastWishPlugin());
        console2.log('LastWishPlugin Deployed:', deployedAddress);
    }
}
