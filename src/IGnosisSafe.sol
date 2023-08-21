// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Enum} from "./Enum.sol";

interface IGnosisSafe {
    function nonce() external view returns (uint256);

    function getOwners() external view returns (address[] memory);

    function enableModule(address module) external;

    function disableModule(address module) external;

    function isOwner(address owner) external view returns (bool);

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32)
}
