// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

library LibTheBadge {
    /**
     * =========================
     * Types
     * =========================
     */
    enum PaymentType {
        ProtocolFee,
        CreatorMintFee,
        UserRegistrationFee,
        UserVerificationFee
    }
    /**
     * =========================
     * Errors
     * =========================
     */
    error TheBadge__SBT();
    error TheBadge__controller_invalidController();
    error TheBadge__controller_controllerIsPaused();

    error TheBadge__requestBadge_badgeModelNotFound();
    error TheBadge__requestBadge_badgeModelIsSuspended();
    error TheBadge__requestBadge_wrongValue();
    error TheBadge__requestBadge_badgeNotMintable();
    error TheBadge__requestBadge_isPaused();
    error TheBadge__requestBadge_isSuspended();
    error TheBadge__requestBadge_isDeprecated();
    error TheBadge__requestBadge_controllerIsPaused();
    error TheBadge__requestBadge_badgeNotFound();
    error TheBadge__requestBadge_badgeNotClaimable();

    error TheBadge__mint_protocolFeesPaymentFailed();
    error TheBadge__mint_creatorFeesPaymentFailed();
    error TheBadge__calculateFee_protocolFeesInvalidValues();

    error TheBadge__theBadgeUsers_method_execution_failed();
    error TheBadge__theBadgeModels_method_execution_failed();
    error TheBadge__theBadge_method_execution_failed();
    error TheBadge__proxy_method_not_supported();
}
