// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library LibTheBadgeStore {
    /**
     * =========================
     * Errors
     * =========================
     */
    error TheBadge__Store_OperationNotPermitted();

    /**
     * =========================
     * Events
     * =========================
     */
    // Event to log when a contract is added to the list
    event ContractAdded(address indexed contractAddress);

    // Event to log when a contract is removed from the list
    event ContractRemoved(address indexed contractAddress);
}
