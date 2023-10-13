// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { IArbitrator } from "../../lib/erc-792/contracts/IArbitrator.sol";

/**
 *  @title LightGeneralizedTCR
 *  Aa curated registry for any types of items. Just like a TCR contract it features the request-challenge protocol and appeal fees crowdfunding.
 *  The difference between LightGeneralizedTCR and GeneralizedTCR is that instead of storing item data in storage and event logs,
 *  LightCurate only stores the URI of item in the logs. This makes it considerably cheaper to use and allows more flexibility with the item columns.
 */
interface ILightGeneralizedTCR {
    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    enum Party {
        None, // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change a status.
        Challenger // Party that challenges the request to change a status.
    }

    enum RequestType {
        Registration, // Identifies a request to register an item to the registry.
        Clearing // Identifies a request to remove an item from the registry.
    }

    enum DisputeStatus {
        None, // No dispute was created.
        AwaitingRuling, // Dispute was created, but the final ruling was not given yet.
        Resolved // Dispute was ruled.
    }

    struct Item {
        Status status; // The current status of the item.
        uint128 sumDeposit; // The total deposit made by the requester and the challenger (if any).
        uint120 requestCount; // The number of requests.
        mapping(uint256 => Request) requests; // List of status change requests made for the item in the form requests[requestID].
    }

    // Arrays with 3 elements map with the Party enum for better readability:
    // - 0: is unused, matches `Party.None`.
    // - 1: for `Party.Requester`.
    // - 2: for `Party.Challenger`.
    struct Request {
        RequestType requestType;
        uint64 submissionTime; // Time when the request was made. Used to track when the challenge period ends.
        uint24 arbitrationParamsIndex; // The index for the arbitration params for the request.
        address payable requester; // Address of the requester.
        // Pack the requester together with the other parameters, as they are written in the same request.
        address payable challenger; // Address of the challenger, if any.
    }

    struct DisputeData {
        uint256 disputeID; // The ID of the dispute on the arbitrator.
        DisputeStatus status; // The current status of the dispute.
        Party ruling; // The ruling given to a dispute. Only set after it has been resolved.
        uint240 roundCount; // The number of rounds.
        mapping(uint256 => Round) rounds; // Data of the different dispute rounds. rounds[roundId].
    }

    struct Round {
        Party sideFunded; // Stores the side that successfully paid the appeal fees in the latest round. Note that if both sides have paid a new round is created.
        uint256 feeRewards; // Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
        uint256[3] amountPaid; // Tracks the sum paid for each Party in this round.
        mapping(address => uint256[3]) contributions; // Maps contributors to their contributions for each side in the form contributions[address][party].
    }

    struct ArbitrationParams {
        IArbitrator arbitrator; // The arbitrator trusted to solve disputes for this request.
        bytes arbitratorExtraData; // The extra data for the trusted arbitrator of this request.
    }

    /**
     * @dev Submit a request to register an item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _item The URI to the item data.
     */
    function addItem(string calldata _item) external payable;

    /**
     * @dev Directly add an item to the list bypassing request-challenge. Can only be used by the relay contract.
     * @param _item The URI to the item data.
     */
    function addItemDirectly(string calldata _item) external;

    /**
     * @dev Submit a request to remove an item from the list. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _itemID The ID of the item to remove.
     * @param _evidence A link to an evidence using its URI. Ignored if not provided.
     */
    function removeItem(bytes32 _itemID, string calldata _evidence) external payable;

    /**
     * @dev Directly remove an item from the list bypassing request-challenge. Can only be used by the relay contract.
     * @param _itemID The ID of the item to remove.
     */
    function removeItemDirectly(bytes32 _itemID) external;

    /**
     * @dev Challenges the request of the item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _itemID The ID of the item which request to challenge.
     * @param _evidence A link to an evidence using its URI. Ignored if not provided.
     */
    function challengeRequest(bytes32 _itemID, string calldata _evidence) external payable;

    /**
     * @dev Takes up to the total amount required to fund a side of an appeal. Reimburses the rest. Creates an appeal if both sides are fully funded.
     * @param _itemID The ID of the item which request to fund.
     * @param _side The recipient of the contribution.
     */
    function fundAppeal(bytes32 _itemID, Party _side) external payable;

    /**
     * @dev If a dispute was raised, sends the fee stake rewards and reimbursements proportionally to the contributions made to the winner of a dispute.
     * @param _beneficiary The address that made contributions to a request.
     * @param _itemID The ID of the item submission to withdraw from.
     * @param _requestID The request from which to withdraw from.
     * @param _roundID The round from which to withdraw from.
     */
    function withdrawFeesAndRewards(
        address payable _beneficiary,
        bytes32 _itemID,
        uint256 _requestID,
        uint256 _roundID
    ) external;

    /**
     * @dev Executes an unchallenged request if the challenge period has passed.
     * @param _itemID The ID of the item to execute.
     */
    function executeRequest(bytes32 _itemID) external;

    /**
     * @dev Give a ruling for a dispute. Can only be called by the arbitrator. TRUSTED.
     * Accounts for the situation where the winner loses a case due to paying less appeal fees than expected.
     * @param _disputeID ID of the dispute in the arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Refused to arbitrate".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;

    /**
     * @dev Submit a reference to evidence. EVENT.
     * @param _itemID The ID of the item which the evidence is related to.
     * @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(bytes32 _itemID, string calldata _evidence) external;

    /**
     * @dev Gets the evidengeGroupID for a given item and request.
     * @param _itemID The ID of the item.
     * @param _requestID The ID of the request.
     * @return The evidenceGroupID
     */
    function getEvidenceGroupID(bytes32 _itemID, uint256 _requestID) external pure returns (uint256);

    /**
     * @notice Gets the arbitrator for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator address.
     */
    function arbitrator() external view returns (IArbitrator);

    /**
     * @notice Gets the tcr governor.
     * @return The governor address.
     */
    function governor() external view returns (address);

    /**
     * @notice Gets the tcr admin.
     * @return The admin address.
     */
    function relayerContract() external view returns (address);

    /**
     * @notice Gets the arbitratorExtraData for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator extra data.
     */
    function arbitratorExtraData() external view returns (bytes memory);

    /**
     * @dev Gets the number of times MetaEvidence was updated.
     * @return The number of times MetaEvidence was updated.
     */
    function metaEvidenceUpdates() external view returns (uint256);

    /**
     * @dev Gets the contributions made by a party for a given round of a request.
     * @param _itemID The ID of the item.
     * @param _requestID The request to query.
     * @param _roundID The round to query.
     * @param _contributor The address of the contributor.
     * @return contributions The contributions.
     */
    function getContributions(
        bytes32 _itemID,
        uint256 _requestID,
        uint256 _roundID,
        address _contributor
    ) external view returns (uint256[3] memory contributions);

    /**
     * @dev Returns item's information. Includes the total number of requests for the item
     * @param _itemID The ID of the queried item.
     * @return status The current status of the item.
     * @return numberOfRequests Total number of requests for the item.
     * @return sumDeposit The total deposit made by the requester and the challenger (if any)
     */
    function getItemInfo(
        bytes32 _itemID
    ) external view returns (uint8 status, uint256 numberOfRequests, uint256 sumDeposit);

    /**
     * @dev Gets information on a request made for the item.
     * @param _itemID The ID of the queried item.
     * @param _requestID The request to be queried.
     * @return disputed True if a dispute was raised.
     * @return disputeID ID of the dispute, if any.
     * @return submissionTime Time when the request was made.
     * @return resolved True if the request was executed and/or any raised disputes were resolved.
     * @return parties Address of requester and challenger, if any.
     * @return numberOfRounds Number of rounds of dispute.
     * @return ruling The final ruling given, if any.
     * @return arbitrator The arbitrator trusted to solve disputes for this request.
     * @return arbitratorExtraData The extra data for the trusted arbitrator of this request.
     * @return metaEvidenceID The meta evidence to be used in a dispute for this case.
     */
    function getRequestInfo(
        bytes32 _itemID,
        uint256 _requestID
    )
        external
        view
        returns (
            bool disputed,
            uint256 disputeID,
            uint256 submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint256 numberOfRounds,
            Party ruling,
            IArbitrator arbitrator,
            bytes memory arbitratorExtraData,
            uint256 metaEvidenceID
        );

    /**
     * @dev Gets the information of a round of a request.
     * @param _itemID The ID of the queried item.
     * @param _requestID The request to be queried.
     * @param _roundID The round to be queried.
     * @return appealed Whether appealed or not.
     * @return amountPaid Tracks the sum paid for each Party in this round.
     * @return hasPaid True if the Party has fully paid its fee in this round.
     * @return feeRewards Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
     */
    function getRoundInfo(
        bytes32 _itemID,
        uint256 _requestID,
        uint256 _roundID
    ) external view returns (bool appealed, uint256[3] memory amountPaid, bool[3] memory hasPaid, uint256 feeRewards);

    /**
     * @dev gets the base deposit to submit an item.
     */
    function submissionBaseDeposit() external view returns (uint256);

    /**
     * @dev gets the base deposit to remove an item.
     */
    function removalBaseDeposit() external view returns (uint256);

    /**
     * @dev gets the base deposit to challenge a submission.
     */
    function submissionChallengeBaseDeposit() external view returns (uint256);

    /**
     * @dev gets the base deposit to challenge a removal request.
     */
    function removalChallengeBaseDeposit() external view returns (uint256);

    /**
     * @dev gets the time after a request becomes executable if not challenged.
     */
    function challengePeriodDuration() external view returns (uint256);

    /**
     * @dev gets array that maps the TCR item ID to its data in the form items[_itemID].
     */
    function items(bytes32 item) external view returns (Status status, uint128 sumDeposit, uint120 requestCount);
}
