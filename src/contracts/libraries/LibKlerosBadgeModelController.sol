// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

library LibKlerosBadgeModelController {
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

    error KlerosBadgeModelController__badge__depositReturnFailed();

    error KlerosBadgeModelController__store_InvalidContractName();
    error KlerosBadgeModelController__store_OperationNotPermitted();
    error KlerosBadgeModelController__store_InvalidContractAddress();
    error KlerosBadgeModelController__store_ContractNameAlreadyExists();

    error KlerosBadgeModelController__method_not_supported();
}
