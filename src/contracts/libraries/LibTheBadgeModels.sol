// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library LibTheBadgeModels {
    /**
     * =========================
     * Errors
     * =========================
     */
    error TheBadge__addBadgeModelController_emptyName();
    error TheBadge__addBadgeModelController_alreadySet();
    error TheBadge__updateBadgeModel_badgeModelNotFound();

    error TheBadge__createBadgeModel_wrongValue();
    error TheBadge__updateBadgeModel_notBadgeModelOwner();
    error TheBadge__badgeModel_badgeModelNotFound();

    error TheBadge__method_not_supported();

    /**
     * =========================
     * Events
     * =========================
     */
    event BadgeModelCreated(uint256 indexed badgeModelId, string metadata);
    event BadgeModelUpdated(uint256 indexed badgeModelId);
    event BadgeModelControllerAdded(string indexed controllerName, address indexed controllerAddress);
}
