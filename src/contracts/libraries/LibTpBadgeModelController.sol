// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library LibTpBadgeModelController {
    string public constant REGISTRATION_META_EVIDENCE = "ipfs://registrationMetaEvidence";
    string public constant CLEARING_META_EVIDENCE = "ipfs://clearingMetaEvidence";
    uint256 public constant CHALLENGE_TIME_SECONDS = 60; // 1 min
    uint256 public constant COURT_ID = 0;
    uint256 public constant NUMBER_OF_JURORS = 1;
    uint256 public constant CHALLENGE_COST = 10000000000000000000000; // 10k ETH
    uint256 public constant THIRD_PARTY_BASE_DEPOSIT = CHALLENGE_COST;
    uint256 public constant THIRD_PARTY_STAKE_MULTIPLIER = 100;

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
    error ThirdPartyModelController__createBadgeModel_badgeModelAlreadyCreated();
    error ThirdPartyModelController__createBadgeModel_TCRListAddressZero();

    error ThirdPartyModelController__onlyTheBadge_senderNotTheBadge();
    error ThirdPartyModelController__onlyTheBadge_senderNotTheBadgeModels();
    error ThirdPartyModelController__onlyTheBadge_senderNotTheBadgeUsers();

    error ThirdPartyModelController__mintBadge_wrongValue();

    error ThirdPartyModelController__claimBadge_notAllowed();
    error ThirdPartyModelController__claimBadge_invalidRecipient();
    error ThirdPartyModelController__claimBadge_invalidBadgeOrAlreadyClaimed();
    error ThirdPartyModelController__claimBadge_userNotAllowed();

    error ThirdPartyModelController__badge__tcrKlerosBadgeNotFound();

    error ThirdPartyModelController__user__userVerificationAlreadyStarted();
    error ThirdPartyModelController__user__userVerificationNotStarted();
    error ThirdPartyModelController__user__userNotFound();

    error ThirdPartyModelController__store_InvalidContractName();
    error ThirdPartyModelController__store_OperationNotPermitted();
    error ThirdPartyModelController__store_InvalidContractAddress();
    error ThirdPartyModelController__store_ContractNameAlreadyExists();

    error ThirdPartyModelController__method_not_supported();
}
