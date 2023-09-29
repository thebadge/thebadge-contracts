// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library LibKlerosBadgeModelController {
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
    error KlerosBadgeModelController__createBadgeModel_badgeModelAlreadyCreated();
    error KlerosBadgeModelController__onlyTheBadge_senderNotTheBadge();
    error KlerosBadgeModelController__onlyTheBadge_senderNotTheBadgeModels();
    error KlerosBadgeModelController__onlyTheBadge_senderNotTheBadgeUsers();
    error KlerosBadgeModelController__mintBadge_alreadyMinted();
    error KlerosBadgeModelController__mintBadge_wrongBadgeModel();
    error KlerosBadgeModelController__mintBadge_isPaused();
    error KlerosBadgeModelController__mintBadge_wrongValue();
    error KlerosBadgeModelController__claimBadge_insufficientBalance();
    error KlerosBadgeModelController__createBadgeModel_TCRListAddressZero();

    error KlerosBadgeModelController__badge__notInChallengeableStatus();
    error KlerosBadgeModelController__badge__klerosBadgeNotFound();
    error KlerosBadgeModelController__badgeModel__NotFound();
    error KlerosBadgeModelController__badge__tcrKlerosBadgeNotFound();

    error KlerosBadgeModelController__user__userVerificationAlreadyStarted();
    error KlerosBadgeModelController__user__userVerificationNotStarted();
    error KlerosBadgeModelController__user__userVerificationRejected();
    error KlerosBadgeModelController__user__userNotFound();

    error KlerosBadgeModelController__badge__depositReturnFailed();

    error KlerosBadgeModelController__store_InvalidContractName();
    error KlerosBadgeModelController__store_OperationNotPermitted();
    error KlerosBadgeModelController__store_InvalidContractAddress();
    error KlerosBadgeModelController__store_ContractNameAlreadyExists();

    error TheBadge__method_not_supported();
}
