// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { IArbitrator } from "../../../lib/erc-792/contracts/IArbitrator.sol";
import { CappedMath } from "../../utils/CappedMath.sol";
import { LibKlerosBadgeModelController } from "../libraries/LibKlerosBadgeModelController.sol";
import { TheBadgeRoles } from "../thebadge/TheBadgeRoles.sol";

contract KlerosBadgeModelControllerStore is TheBadgeRoles {
    using CappedMath for uint256;

    /**
     * Struct to use as args to create a Kleros badge type strategy.
     *  @param owner address of the creator of the model
     *  @param governor An address with permission to updates parameters of the list. Use Kleros governor for full decentralization.
     *  @param courtId The ID of the kleros's court.
     *  @param numberOfJurors The number of jurors required if a dispute is initiated.
     *  @param registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param stakeMultipliers Multipliers of the arbitration cost in basis points (see GeneralizedTCR MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round (e.g. when it's the first round or the arbitrator refused to arbitrate).
     *  - The multiplier applied to the winner's fee stake for an appeal round.
     *  - The multiplier applied to the loser's fee stake for an appeal round.
     */
    struct CreateBadgeModel {
        address governor;
        uint256 courtId;
        uint256 numberOfJurors;
        string registrationMetaEvidence;
        string clearingMetaEvidence;
        uint256 challengePeriodDuration;
        uint256[4] baseDeposits;
        uint256[3] stakeMultipliers;
    }

    struct MintParams {
        string evidence;
    }

    struct AddEvidenceParams {
        string evidence;
    }

    /**
     * @param owner address of the creator of the model
     * @param tcrList The TCR List created for a particular badge type
     */
    struct KlerosBadgeModel {
        address owner;
        uint256 badgeModelId;
        address tcrList;
        address governor;
        address admin;
        bool initialized;
    }

    /**
     * @param itemID internal Kleros TCR list ID
     * @param callee address paying the deposit
     * @param deposit the deposit amount
     */
    struct KlerosBadge {
        bytes32 itemID;
        uint256 badgeModelId;
        address callee;
        uint256 deposit;
        address destinationAddress;
        bool initialized;
    }

    struct KlerosUser {
        address user;
        string userMetadata;
        string verificationEvidence;
        LibKlerosBadgeModelController.VerificationStatus verificationStatus;
        bool initialized;
    }

    /**
     * =========================
     * Store
     * =========================
     */
    uint256 internal klerosBadgeModelIdsCounter;
    uint256 internal klerosBadgeIdsCounter;
    IArbitrator public arbitrator;
    address public tcrFactory;
    uint256 internal verifyUserProtocolFee;

    // Mapping to store contract addresses by name
    mapping(address => bool) public allowedContractAddresses;
    mapping(string => address) public allowedContractAddressesByContractName;
    mapping(uint256 => KlerosBadgeModel) public klerosBadgeModels;
    mapping(uint256 => KlerosBadge) public klerosBadges;
    mapping(address => KlerosUser) public klerosUsers;

    /**
     * =========================
     * Getters
     * =========================
     */
    /**
     * @notice Get the current badge model id
     * @return The current badgeModelId counter
     */
    function getCurrentBadgeModelsIdCounter() external view returns (uint256) {
        return klerosBadgeModelIdsCounter;
    }

    /**
     * @notice Get the current badge id
     * @return The current badgeId counter
     */
    function getCurrentBadgeIdCounter() external view returns (uint256) {
        return klerosBadgeIdsCounter;
    }

    /**
     * =========================
     * Setters
     * =========================
     */

    /**
     * @notice Create a new KlerosBadgeModel.
     * @param _badgeModelId The ID of the KlerosBadgeModel to create.
     * @param _owner The address of the owner of the KlerosBadgeModel.
     * @param _tcrList The address of the TCR list associated with the KlerosBadgeModel.
     * @param _governor The address governor of the TCR list associated.
     * @param _admin The address _admin of the TCR list associated.
     */
    function createKlerosBadgeModel(
        uint256 _badgeModelId,
        address _owner,
        address _tcrList,
        address _governor,
        address _admin
    ) internal {
        KlerosBadgeModel storage badgeModel = klerosBadgeModels[_badgeModelId];

        if (badgeModel.initialized == true) {
            revert LibKlerosBadgeModelController
                .KlerosBadgeModelController__createBadgeModel_badgeModelAlreadyCreated();
        }

        klerosBadgeModels[_badgeModelId] = KlerosBadgeModel({
            owner: _owner,
            badgeModelId: _badgeModelId,
            tcrList: _tcrList,
            governor: _governor,
            admin: _admin,
            initialized: true
        });

        klerosBadgeModelIdsCounter++;
    }

    /**
     * @notice Add a new KlerosBadge.
     * @param badgeId The ID of the KlerosBadge.
     * @param badge The KlerosBadge struct to be added.
     */
    function addKlerosBadge(uint256 badgeId, KlerosBadge memory badge) internal {
        klerosBadges[badgeId] = badge;
        klerosBadgeIdsCounter++;
    }

    /**
     * @notice Clears the deposit amount for a specific KlerosBadge.
     *
     * This function allows the owner or a permitted contract to clear the deposit amount associated with a KlerosBadge.
     *
     * @dev The deposit amount for the KlerosBadge is set to 0.
     * @param badgeId The ID of the KlerosBadge for which to clear the deposit amount.
     */
    function clearKlerosBadgeDepositAmount(uint256 badgeId) internal {
        KlerosBadge storage existingBadge = klerosBadges[badgeId];

        if (!existingBadge.initialized) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        existingBadge.deposit = 0;
    }

    /**
     * @notice Creates a KlerosUser's details.
     * @param userAddress The address of the user to be created.
     * @param newUser The new KlerosUser struct.
     */
    function registerKlerosUser(address userAddress, KlerosUser memory newUser) internal {
        KlerosUser memory _user = klerosUsers[userAddress];
        if (_user.initialized == true) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__user__userVerificationAlreadyStarted();
        }
        klerosUsers[userAddress] = newUser;
    }

    /**
     * @notice Update a KlerosUser's details.
     * @param userAddress The address of the user to be updated.
     * @param _verificationStatus the new verification status of the user
     */
    function updateKlerosUserVerificationStatus(
        address userAddress,
        LibKlerosBadgeModelController.VerificationStatus _verificationStatus
    ) internal {
        KlerosUser memory _user = klerosUsers[userAddress];
        if (_user.initialized == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__user__userNotFound();
        }
        _user.verificationStatus = _verificationStatus;
        klerosUsers[userAddress] = _user;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
