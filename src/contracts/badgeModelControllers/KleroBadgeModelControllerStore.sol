// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { IArbitrator } from "../../../lib/erc-792/contracts/IArbitrator.sol";
import { TheBadge } from "../thebadge/TheBadge.sol";
import "../../utils/CappedMath.sol";

contract KlerosBadgeModelControllerStore {
    TheBadge public theBadge;
    IArbitrator public arbitrator;
    address public tcrFactory;

    using CappedMath for uint256;

    /**
     * Struct to use as args to create a Kleros badge type strategy.
     *  @param governor An address with permission to updates parameters of the list. Use Kleros governor for full decentralization.
     *  @param admin The address with permission to add/remove items directly.
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
        address admin;
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

    /**
     * @param tcrList The TCR List created for a particular badge type
     */
    struct KlerosBadgeModel {
        address tcrList;
    }

    /**
     * @param itemID internal Kleros TCR list ID
     * @param callee address paying the deposit
     * @param deposit the deposit amount
     */
    struct KlerosBadge {
        bytes32 itemID;
        address callee;
        uint256 deposit;
    }

    /**
     * =========================
     * Store
     * =========================
     */

    mapping(uint256 => KlerosBadgeModel) public klerosBadgeModel;
    mapping(uint256 => KlerosBadge) public klerosBadge;

    /**
     * =========================
     * Events
     * =========================
     */
    event NewKlerosBadgeModel(uint256 indexed badgeModelId, address indexed tcrAddress, string metadataUri);
    event MintKlerosBadge(uint256 indexed badgeId, string evidence);
    event KlerosBadgeChallenged(uint256 indexed badgeId, address indexed wallet, string evidence, address sender);
    event DepositReturned(address indexed recipient, uint256 amount, uint256 indexed badgeId);

    /**
     * =========================
     * Errors
     * =========================
     */
    error KlerosBadgeModelController__createBadgeModel_badgeModelAlreadyCreated();
    error KlerosBadgeModelController__onlyTheBadge_senderNotTheBadge();
    error KlerosBadgeModelController__mintBadge_alreadyMinted();
    error KlerosBadgeModelController__mintBadge_wrongBadgeModel();
    error KlerosBadgeModelController__mintBadge_isPaused();
    error KlerosBadgeModelController__mintBadge_wrongValue();
    error KlerosBadgeModelController__claimBadge_insufficientBalance();
    error KlerosBadgeModelController__createBadgeModel_TCRListAddressZero();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyTheBadge() {
        if (address(theBadge) != msg.sender) {
            revert KlerosBadgeModelController__onlyTheBadge_senderNotTheBadge();
        }
        _;
    }
}
