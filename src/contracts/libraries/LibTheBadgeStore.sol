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
}
