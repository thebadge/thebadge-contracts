// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

library LibTheBadgeUsers {
    enum VerificationStatus {
        VerificationSubmitted, // The user submitted a request to verify himself
        Verified, // The verification was granted to the user
        VerificationRejected // The verification was rejected after qhe submission
    }

    /**
     * =========================
     * Errors
     * =========================
     */
    error TheBadge__onlyUser_userNotFound();
    error TheBadge__onlyCreator_senderIsNotACreator();
    error TheBadge__onlyCreator_senderIsAlreadyACreator();
    error TheBadge__users__onlyCreator_creatorIsSuspended();

    error TheBadge__registerUser_wrongValue();
    error TheBadge__registerUser_alreadyRegistered();
    error TheBadge__updateUser_notFound();
    error TheBadge__updateUser_wrongMetadata();

    error TheBadge__verifyUser_wrongValue();
    error TheBadge__verifyUser_verificationProtocolFeesPaymentFailed();
    error TheBadge__verifyUser__userVerificationAlreadyStarted();
    error TheBadge__verifyUser__userVerificationNotStarted();
    error TheBadge__verifyUser__userVerificationRejected();
}
