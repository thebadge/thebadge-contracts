// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { TheBadgeStore } from "../thebadge/TheBadgeStore.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { LibTheBadge } from "../libraries/LibTheBadge.sol";

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
}
