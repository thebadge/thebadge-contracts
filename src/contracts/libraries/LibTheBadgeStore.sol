// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library LibTheBadgeStore {
    /**
     * =========================
     * Errors
     * =========================
     */
    error TheBadge__Store_OperationNotPermitted();
    error TheBadge__Store_InvalidContractAddress();
    error TheBadge__Store_ContractNameAlreadyExists();
    error TheBadge__Store_InvalidContractName();

    /**
     * =========================
     * Events
     * =========================
     */
    // Event to log when a contract is added to the list
    event ContractAdded(string indexed _contractName, address indexed contractAddress);

    // Event to log when a contract is removed from the list
    event ContractRemoved(string indexed _contractName, address indexed contractAddress);

    // Event to log when a contract address is updated from the list
    event ContractUpdated(string indexed _contractName, address indexed contractAddress);
}
