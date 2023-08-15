// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "../../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../../interfaces/ILightGTCRFactory.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../interfaces/IBadgeModelController.sol";
import "./KleroBadgeModelControllerStore.sol";
import "../thebadge/TheBadgeRoles.sol";

contract KlerosBadgeModelController is
    Initializable,
    KlerosBadgeModelControllerStore,
    UUPSUpgradeable,
    TheBadgeRoles,
    IBadgeModelController
{
    using CappedMath for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() initializer {}

    function initialize(address admin, address _theBadge, address _arbitrator, address _tcrFactory) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        theBadge = TheBadge(payable(_theBadge));
        arbitrator = IArbitrator(_arbitrator);
        tcrFactory = _tcrFactory;
    }

    /**
     * @notice Allows to create off-chain kleros strategies for registered entities
     * @param badgeModelId from TheBadge contract
     * @param data Encoded data required to create a Kleros TCR list
     */
    function createBadgeModel(uint256 badgeModelId, bytes calldata data) public onlyTheBadge {
        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];
        if (_klerosBadgeModel.tcrList != address(0)) {
            revert KlerosBadgeModelController__createBadgeModel_badgeModelAlreadyCreated();
        }

        ILightGTCRFactory lightGTCRFactory = ILightGTCRFactory(tcrFactory);

        CreateBadgeModel memory args = abi.decode(data, (CreateBadgeModel));

        lightGTCRFactory.deploy(
            IArbitrator(arbitrator), // Arbitrator address
            bytes.concat(abi.encodePacked(args.courtId), abi.encodePacked(args.numberOfJurors)), // ArbitratorExtraData
            address(0), // TODO: check this. The address of the TCR that stores related TCR addresses. This parameter can be left empty.
            args.registrationMetaEvidence, // The URI of the meta evidence object for registration requests.
            args.clearingMetaEvidence, // The URI of the meta evidence object for clearing requests.
            args.governor, // The trusted governor of this contract.
            args.baseDeposits, // The base deposits for requests/challenges (4 values: submit, remove, challenge and removal request)
            args.challengePeriodDuration, // The time in seconds parties have to challenge a request.
            args.stakeMultipliers, // Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR)
            args.admin // The address of the relay contract to add/remove items directly. // TODO: set TCR admin to an address that we control, so we can call "removeItem", only for Third-party badges
        );

        // Get the address for the kleros badge model created
        uint256 index = lightGTCRFactory.count() - 1;
        address klerosTcrListAddress = address(lightGTCRFactory.instances(index));
        if (klerosTcrListAddress == address(0)) {
            revert KlerosBadgeModelController__createBadgeModel_TCRListAddressZero();
        }

        klerosBadgeModel[badgeModelId] = KlerosBadgeModel(klerosTcrListAddress);

        emit NewKlerosBadgeModel(
            badgeModelId,
            klerosTcrListAddress,
            args.registrationMetaEvidence,
            args.clearingMetaEvidence
        );
    }

    /**
     * @notice mints a klerosBadge
     * @param callee the address that called the mint() function, it could be different than the recipient (for instance: it could be a relayer)
     * @param badgeModelId the badgeModelId
     * @param badgeId the klerosBadgeId
     * @param data the klerosBadgeId
     */
    function mint(
        address callee,
        uint256 badgeModelId,
        uint256 badgeId,
        bytes calldata data
    ) public payable onlyTheBadge returns (uint256) {
        // check value
        uint256 mintCost = mintValue(badgeModelId);
        if (msg.value != mintCost) {
            revert KlerosBadgeModelController__mintBadge_wrongValue();
        }

        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);
        MintParams memory args = abi.decode(data, (MintParams));

        // TODO: it would be good to emit and mintKlerosBadge which the badgeId
        // and the klerosItemID (which can be calculated here, before adding the item in TCR)
        // but could it cause some issues if the item it's not added on the next line?
        // Note: it would be good, as it will simplify a lot the logic on the subgraph, not needing to listen to internal TCR events
        // in order to track the item
        lightGeneralizedTCR.addItem{ value: (msg.value) }(args.evidence);

        // Calculates which is the itemID inside the klerosTCR list
        // Its needed on the subgraph to check the disputes status for that item
        bytes32 klerosItemID = keccak256(abi.encodePacked(args.evidence));
        // save deposit amount for callee as it has to be returned if it was not challenged.
        klerosBadge[badgeId] = KlerosBadge(klerosItemID, callee, msg.value, true);

        emit MintKlerosBadge(badgeId, args.evidence);
        return uint256(klerosItemID);
    }

    /**
     * @notice After the review period ends, the items on the tcr list should be claimed using this function
     * returns the badge's mint callee deposit and set the internal value to 0 again
     * the internal value is not the deposit, is just a counter to know how much money belongs to the deposit
     * @param badgeId the klerosBadgeId
     */
    function claim(uint256 badgeId, bytes calldata /*data*/) public onlyTheBadge {
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        KlerosBadge memory _klerosBadge = klerosBadge[badgeId];

        // This changes the state of the item from Requested to Accepted and returns the deposit to our contract
        lightGeneralizedTCR.executeRequest(_klerosBadge.itemID);

        // If this contract (KlerosBadgeModelController) didn't received the deposit, we throw an error
        if (_klerosBadge.deposit > address(this).balance) {
            revert KlerosBadgeModelController__claimBadge_insufficientBalance();
        }

        uint256 balanceToDeposit = _klerosBadge.deposit;
        _klerosBadge.deposit = 0;
        // Then we return the deposit from within our contract to the callee address
        // TODO: review if this is safe enough
        (bool badgeDepositSent, ) = payable(_klerosBadge.callee).call{ value: balanceToDeposit }("");
        require(badgeDepositSent, "Failed to return the deposit");
        emit DepositReturned(_klerosBadge.callee, balanceToDeposit, badgeId);
    }

    /**
     * @notice Given a badge and the evidenceHash, submits a challenge against the controller
     * @param badgeId the id of the badge
     * @param data encoded evidenceHash ipfs hash containing the evidence to generate the challenge
     */
    function challenge(uint256 badgeId, bytes calldata data) external payable onlyTheBadge {
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];

        if (_klerosBadge.initialized == false) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        string memory evidenceHash = abi.decode(data, (string));
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        lightGeneralizedTCR.challengeRequest{ value: (msg.value) }(_klerosBadge.itemID, evidenceHash);
    }

    /**
     * @notice Given a badge and the evidenceHash, submits a removal request against the controller
     * @param badgeId the id of the badge
     * @param data encoded evidenceHash ipfs hash containing the evidence to generate the removal request
     */
    function removeItem(uint256 badgeId, bytes calldata data) external payable onlyTheBadge {
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];

        if (_klerosBadge.initialized == false) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        string memory evidenceHash = abi.decode(data, (string));
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        lightGeneralizedTCR.removeItem{ value: (msg.value) }(_klerosBadge.itemID, evidenceHash);
    }

    /**
     * @notice Given a badge and the evidenceHash, adds more evidence to a case
     * @param badgeId the id of the badge
     * @param data encoded evidenceHash ipfs hash adding more evidence to a submission
     */
    function submitEvidence(uint256 badgeId, bytes calldata data) external onlyTheBadge {
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];

        if (_klerosBadge.initialized == false) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        string memory evidenceHash = abi.decode(data, (string));
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        lightGeneralizedTCR.submitEvidence(_klerosBadge.itemID, evidenceHash);
    }

    /**
     * @notice Returns the cost for minting a badge for a kleros controller, its the result of doing klerosBaseDeposit + klerosArbitrationCost
     * @param badgeModelId the badgeModelId
     */
    function mintValue(uint256 badgeModelId) public view returns (uint256) {
        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);

        uint256 arbitrationCost = arbitrator.arbitrationCost(lightGeneralizedTCR.arbitratorExtraData());
        uint256 baseDeposit = lightGeneralizedTCR.submissionBaseDeposit();

        return arbitrationCost + baseDeposit;
    }

    /**
     * @notice Badge can be minted if it was never requested for the address or if it has a due date before now
     */
    function isMintable(uint256, address) public pure returns (bool) {
        // TODO: implementation missing?
        return true;
    }

    /**
     * @notice Returns true if the badge is ready to be claimed (its status is RegistrationRequested and the challenge period ended), otherwise returns false
     * @param badgeId the klerosBadgeId
     */
    function isClaimable(uint256 badgeId) public view returns (bool) {
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];

        if (_klerosBadge.initialized == false) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        (, , uint120 requestCount) = lightGeneralizedTCR.items(_klerosBadge.itemID);
        (uint8 klerosItemStatus, , ) = lightGeneralizedTCR.getItemInfo(_klerosBadge.itemID);
        uint256 lastRequestIndex = requestCount - 1;
        (, , uint256 submissionTime, , , , , , , ) = lightGeneralizedTCR.getRequestInfo(
            _klerosBadge.itemID,
            lastRequestIndex
        );
        uint256 challengePeriodDuration = lightGeneralizedTCR.challengePeriodDuration();

        // The status is RegistrationRequested
        bool challengePeriodEnded = block.timestamp - submissionTime > challengePeriodDuration ? true : false;
        if (klerosItemStatus == 2 && challengePeriodEnded == true) {
            return true;
        }

        return false;
    }

    /**
     * @notice Checks the status of the badge within the Kleros TCR, returns true if the status is (1 = registered or 3 = clearing/removal requested)
     * It returns false for the other statuses (0 = absent; 2 = registration requested)
     * @param badgeId the klerosBadgeId
     */
    function isAssetActive(uint256 badgeId) public view returns (bool) {
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];

        (uint8 klerosItemStatus, , ) = lightGeneralizedTCR.getItemInfo(_klerosBadge.itemID);
        // The status is REGISTERED or ClearingRequested
        if (klerosItemStatus == 1 || klerosItemStatus == 3) {
            return true;
        }

        return false;
    }

    /**
     * @notice Get the cost of generating a challengeRequest in kleros TCR to the given badgeId
     * @param badgeId the klerosBadgeId
     */
    function getChallengeDepositValue(uint256 badgeId) public view returns (uint256) {
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];

        if (_klerosBadge.initialized == false) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        (uint8 klerosItemStatus, , ) = lightGeneralizedTCR.getItemInfo(_klerosBadge.itemID);
        uint256 arbitrationCost = getBadgeIdArbitrationCosts(badgeId);

        // Status 1: The item is awaiting to be registered and the request if to challenge the registration
        if (klerosItemStatus == 1) {
            return arbitrationCost.addCap(lightGeneralizedTCR.submissionChallengeBaseDeposit());
        }

        // Status 2: The item is registered and the request is to remove the item
        if (klerosItemStatus == 2) {
            return arbitrationCost.addCap(lightGeneralizedTCR.removalBaseDeposit());
        }

        // Status 2: The item is challenged, no costs involved.
        if (klerosItemStatus == 3) {
            return 0;
        }

        // Status 4: The item is inside the list but a request to remove it started, this is for challenge against that request
        if (klerosItemStatus == 4) {
            return arbitrationCost.addCap(lightGeneralizedTCR.removalChallengeBaseDeposit());
        }

        revert KlerosBadgeModelController__badge__notInChallengeableStatus();
    }

    /**
     * @notice Get the cost of generating a removalRequest in kleros TCR to the given badgeId
     * @param badgeId the klerosBadgeId
     */
    function getRemovalDepositValue(uint256 badgeId) public view returns (uint256) {
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);

        uint256 arbitrationCost = getBadgeIdArbitrationCosts(badgeId);

        uint256 removalBaseDeposit = lightGeneralizedTCR.removalBaseDeposit();

        return arbitrationCost.addCap(removalBaseDeposit);
    }

    /**
     * @notice Internal function that returns the TCR contract instance for a given klerosBadgeModel
     * @param badgeId the klerosBadgeId
     */
    function getLightGeneralizedTCR(uint256 badgeId) internal view returns (ILightGeneralizedTCR) {
        (uint256 badgeModelId, , , ) = theBadge.badges(badgeId);
        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];
        require(_klerosBadgeModel.tcrList != address(0), "Valid klerosBadgeModelId required for TCR!");
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);
        return lightGeneralizedTCR;
    }

    /**
     * @notice Internal function that the current arbitration cost of a request for the given badgeId
     * @param badgeId the klerosBadgeId
     */
    function getBadgeIdArbitrationCosts(uint256 badgeId) internal view returns (uint256) {
        KlerosBadge memory _klerosBadge = klerosBadge[badgeId];
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        (, , uint120 requestCount) = lightGeneralizedTCR.items(_klerosBadge.itemID);
        uint256 lastRequestIndex = requestCount - 1;

        (, , , , , , , , bytes memory requestArbitratorExtraData, ) = lightGeneralizedTCR.getRequestInfo(
            _klerosBadge.itemID,
            lastRequestIndex
        );

        return arbitrator.arbitrationCost(requestArbitratorExtraData);
    }

    /**
     * =========================
     * Overrides
     * =========================
     */
    /// Required by the OZ UUPS module
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}
