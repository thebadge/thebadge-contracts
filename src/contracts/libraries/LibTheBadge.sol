// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

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
    error TheBadge__requestBadge_isPaused();
    error TheBadge__requestBadge_controllerIsPaused();
    error TheBadge__requestBadge_badgeNotFound();
    error TheBadge__requestBadge_badgeNotClaimable();

    error TheBadge__mint_protocolFeesPaymentFailed();
    error TheBadge__mint_creatorFeesPaymentFailed();
    error TheBadge__calculateFee_protocolFeesInvalidValues();
    /**
     * =========================
     * Events
     * =========================
     */
    event PaymentMade(
        address indexed recipient,
        address payer,
        uint256 amount,
        PaymentType indexed paymentType,
        uint256 indexed badgeModelId,
        string controllerName
    );

    event BadgeRequested(
        uint256 indexed badgeModelID,
        uint256 indexed badgeID,
        address indexed recipient,
        address controller,
        uint256 controllerBadgeId
    );
}
