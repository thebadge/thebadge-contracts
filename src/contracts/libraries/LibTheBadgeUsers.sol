// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library LibTheBadgeUsers {
    /**
     * =========================
     * Errors
     * =========================
     */
    error TheBadge__onlyUser_userNotFound();
    error TheBadge__onlyCreator_senderIsNotACreator();
    error TheBadge__onlyCreator_creatorIsSuspended();

    error TheBadge__registerUser_wrongValue();
    error TheBadge__registerUser_alreadyRegistered();
    error TheBadge__updateUser_notFound();

    error TheBadge__verifyUser_wrongValue();
    error TheBadge__verifyUser_verificationProtocolFeesPaymentFailed();
    /**
     * =========================
     * Events
     * =========================
     */
    event UserRegistered(address indexed creator, string metadata);
    event CreatorRegistered(address indexed creator);

    event UserVerificationRequested(address indexed user, string metadata, string controllerName);
    event UserVerificationExecuted(address indexed user, string controllerName, bool verify);
    event UpdatedUserMetadata(address indexed creator, string metadata);
    event SuspendedUser(address indexed creator, bool suspended);
    event RemovedUser(address indexed creator, bool deleted);
}
