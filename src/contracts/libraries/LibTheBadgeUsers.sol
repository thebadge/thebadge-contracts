// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library LibTheBadgeUsers {
    /**
     * =========================
     * Errors
     * =========================
     */
    error TheBadge__registerUser_wrongValue();
    error TheBadge__registerUser_alreadyRegistered();
    error TheBadge__updateUser_notFound();

    /**
     * =========================
     * Events
     * =========================
     */
    event UserRegistered(address indexed creator, string metadata);
    event CreatorRegistered(address indexed creator);
}
