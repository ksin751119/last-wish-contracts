// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {stdJson} from 'forge-std/StdJson.sol';
import {Script} from 'forge-std/Script.sol';

contract DeployBase is Script {
    using stdJson for string;

    error InvalidRegistryAddress();

    struct DeployParameters {
        // role
        address deployer;
        // external
        address registry;
        address manager;
    }

    modifier isRegistryAddressZero(address registry) {
        if (registry == address(0)) revert InvalidRegistryAddress();
        _;
    }

    function setUp() external {}

    function run(string memory pathToJSON) external {
        vm.startBroadcast();
        _run(_fetchParameters(pathToJSON));
        vm.stopBroadcast();
    }

    function _run(DeployParameters memory params) internal virtual returns (address deployedAddress) {}

    function _fetchParameters(string memory pathToJSON) internal view returns (DeployParameters memory params) {
        string memory root = vm.projectRoot();
        string memory json = vm.readFile(string.concat(root, '/', pathToJSON));
        bytes memory rawParams = json.parseRaw('.*');
        (, , params) = abi.decode(rawParams, (bytes32, bytes32, DeployParameters));
    }
}
