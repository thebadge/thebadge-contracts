// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { TheBadgeStore } from "../thebadge/TheBadgeStore.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { LibTheBadgeModels } from "../libraries/LibTheBadgeModels.sol";

library LibTheBadgeUsers {
    /**
     * =========================
     * Errors
     * =========================
     */
    error TheBadge__onlyUser_userNotFound();
    error TheBadge__onlyCreator_senderIsNotACreator();
    error TheBadge__onlyCreator_senderIsAlreadyACreator();
    error TheBadge__onlyCreator_creatorIsSuspended();

    error TheBadge__registerUser_wrongValue();
    error TheBadge__registerUser_alreadyRegistered();
    error TheBadge__updateUser_notFound();

    error TheBadge__verifyUser_wrongValue();
    error TheBadge__verifyUser_verificationProtocolFeesPaymentFailed();
}
