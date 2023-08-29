// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLastWishModule} from './DeployLastWishModule.s.sol';

contract DeployAll is DeployLastWishModule {
    function _run(
        DeployParameters memory params
    ) internal override(DeployLastWishModule) returns (address deployedAddress) {
        // plugin
        deployedAddress = DeployLastWishModule._run(params);
    }
}
