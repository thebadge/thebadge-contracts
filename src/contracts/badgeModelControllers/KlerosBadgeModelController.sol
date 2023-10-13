// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { ILightGeneralizedTCR } from "../../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../../interfaces/ILightGTCRFactory.sol";
import { IArbitrator } from "../../../lib/erc-792/contracts/IArbitrator.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { TheBadgeRoles } from "../thebadge/TheBadgeRoles.sol";
import { KlerosBadgeModelControllerStore } from "./KlerosBadgeModelControllerStore.sol";
import { CappedMath } from "../../utils/CappedMath.sol";
import { IArbitrator } from "../../../lib/erc-792/contracts/IArbitrator.sol";
import { TheBadge } from "../thebadge/TheBadge.sol";
import { LibKlerosBadgeModelController } from "../libraries/LibKlerosBadgeModelController.sol";
import { TheBadgeModels } from "../thebadge/TheBadgeModels.sol";
import { TheBadgeUsers } from "../thebadge/TheBadgeUsers.sol";

contract KlerosBadgeModelController is Initializable, UUPSUpgradeable, TheBadgeRoles, IBadgeModelController {
    using CappedMath for uint256;
    KlerosBadgeModelControllerStore public klerosBadgeModelControllerStore;
    TheBadge public theBadge;
    TheBadgeModels public theBadgeModels;
    TheBadgeUsers public theBadgeUsers;

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyTheBadge() {
        if (address(theBadge) != msg.sender) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__onlyTheBadge_senderNotTheBadge();
        }
        _;
    }

    modifier onlyTheBadgeModels() {
        if (address(theBadgeModels) != msg.sender) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__onlyTheBadge_senderNotTheBadgeModels();
        }
        _;
    }

    modifier onlyTheBadgeUsers() {
        if (address(theBadgeUsers) != msg.sender) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__onlyTheBadge_senderNotTheBadgeUsers();
        }
        _;
    }

    modifier onlyUserOnVerification(address _user) {
        KlerosBadgeModelControllerStore.KlerosUser memory _klerosUser = klerosBadgeModelControllerStore.getKlerosUser(
            _user
        );
        if (_klerosUser.initialized == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__user__userNotFound();
        }
        if (_klerosUser.verificationStatus != LibKlerosBadgeModelController.VerificationStatus.VerificationSubmitted) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__user__userVerificationNotStarted();
        }
        _;
    }

    /**
     * =========================
     * Events
     * =========================
     */
    event Initialize(address indexed admin, address indexed tcrFactory);
    event NewKlerosBadgeModel(
        uint256 indexed badgeModelId,
        address indexed tcrAddress,
        string registrationMetaEvidence,
        string clearingMetaEvidence
    );
    event MintKlerosBadge(uint256 indexed badgeId, string evidence);
    event KlerosBadgeChallenged(uint256 indexed badgeId, address indexed challenger, string evidence);
    event KlerosChallengeEvidenceAdded(uint256 indexed badgeId, address indexed challenger, string evidence);
    event DepositReturned(address indexed recipient, uint256 amount, uint256 indexed badgeId);
    event ProtocolSettingsUpdated();

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address _theBadge,
        address _theBadgeModels,
        address _theBadgeUsers,
        address _klerosBadgeModelControllerStore
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        theBadge = TheBadge(payable(_theBadge));
        theBadgeModels = TheBadgeModels(payable(_theBadgeModels));
        theBadgeUsers = TheBadgeUsers(payable(_theBadgeUsers));
        klerosBadgeModelControllerStore = KlerosBadgeModelControllerStore(payable(_klerosBadgeModelControllerStore));
        address _tcrFactory = klerosBadgeModelControllerStore.getTCRFactory();
        emit Initialize(admin, _tcrFactory);
    }

    /*
     * @notice Updates the value of the protocol: _mintBadgeDefaultFee
     * @param _mintBadgeDefaultFee the default fee that TheBadge protocol charges for each user verification (in bps)
     */
    function updateVerifyUserProtocolFee(uint256 _verifyUserProtocolFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        klerosBadgeModelControllerStore.setVerifyUserProtocolFee(_verifyUserProtocolFee);
        emit ProtocolSettingsUpdated();
    }

    /**
     * @notice Allows to create off-chain kleros strategies for registered entities
     * @param callee the user that originally called the createBadgeModel() function
     * @param badgeModelId from TheBadge contract
     * @param data Encoded data required to create a Kleros TCR list
     */
    function createBadgeModel(address callee, uint256 badgeModelId, bytes calldata data) public onlyTheBadgeModels {
        address _callee = callee;
        KlerosBadgeModelControllerStore.KlerosBadgeModel memory _klerosBadgeModel = klerosBadgeModelControllerStore
            .getKlerosBadgeModel(badgeModelId);
        if (_klerosBadgeModel.tcrList != address(0)) {
            revert LibKlerosBadgeModelController
                .KlerosBadgeModelController__createBadgeModel_badgeModelAlreadyCreated();
        }

        address _tcrFactory = klerosBadgeModelControllerStore.getTCRFactory();
        ILightGTCRFactory lightGTCRFactory = ILightGTCRFactory(_tcrFactory);

        KlerosBadgeModelControllerStore.CreateBadgeModel memory args = abi.decode(
            data,
            (KlerosBadgeModelControllerStore.CreateBadgeModel)
        );

        IArbitrator _arbitrator = klerosBadgeModelControllerStore.getArbitrator();
        address admin = address(0);
        address governor = args.governor != address(0) ? args.governor : _callee;
        lightGTCRFactory.deploy(
            _arbitrator, // Arbitrator address
            bytes.concat(abi.encodePacked(args.courtId), abi.encodePacked(args.numberOfJurors)), // ArbitratorExtraData
            address(0), // TODO: check this. The address of the TCR that stores related TCR addresses. This parameter can be left empty.
            args.registrationMetaEvidence, // The URI of the meta evidence object for registration requests.
            args.clearingMetaEvidence, // The URI of the meta evidence object for clearing requests.
            governor, // The trusted governor of this contract.
            args.baseDeposits, // The base deposits for requests/challenges (4 values: submit, remove, challenge and removal request)
            args.challengePeriodDuration, // The time in seconds parties have to challenge a request.
            args.stakeMultipliers, // Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR)
            admin // The address of the relay contract allowed to add/remove items directly, it should be 0x for decentralized badges
        );

        // Get the address for the kleros badge model created
        uint256 index = lightGTCRFactory.count() - 1;
        address klerosTcrListAddress = address(lightGTCRFactory.instances(index));
        if (klerosTcrListAddress == address(0)) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__tcrKlerosBadgeNotFound();
        }

        klerosBadgeModelControllerStore.createKlerosBadgeModel(
            badgeModelId,
            _callee,
            klerosTcrListAddress,
            governor,
            admin
        );

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
     * @param destinationAddress the address owner of the new badge
     */
    function mint(
        address callee,
        uint256 badgeModelId,
        uint256 badgeId,
        bytes calldata data,
        address destinationAddress
    ) public payable onlyTheBadge returns (uint256) {
        // check value
        uint256 mintCost = mintValue(badgeModelId);
        if (msg.value != mintCost) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__mintBadge_wrongValue();
        }

        KlerosBadgeModelControllerStore.KlerosBadgeModel memory _klerosBadgeModel = klerosBadgeModelControllerStore
            .getKlerosBadgeModel(badgeModelId);
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);
        KlerosBadgeModelControllerStore.MintParams memory args = abi.decode(
            data,
            (KlerosBadgeModelControllerStore.MintParams)
        );

        // and the klerosItemID (which can be calculated here, before adding the item in TCR)
        // but could it cause some issues if the item it's not added on the next line?
        // Note: it would be good, as it will simplify a lot the logic on the subgraph, not needing to listen to internal TCR events
        // in order to track the item
        lightGeneralizedTCR.addItem{ value: (msg.value) }(args.evidence);

        // Calculates which is the itemID inside the klerosTCR list
        // Its needed on the subgraph to check the disputes status for that item
        bytes32 klerosItemID = keccak256(abi.encodePacked(args.evidence));
        // save deposit amount for callee as it has to be returned if it was not challenged.
        KlerosBadgeModelControllerStore.KlerosBadge memory _newKlerosBadge = KlerosBadgeModelControllerStore
            .KlerosBadge(klerosItemID, badgeModelId, callee, msg.value, destinationAddress, true);
        klerosBadgeModelControllerStore.addKlerosBadge(badgeId, _newKlerosBadge);

        emit MintKlerosBadge(badgeId, args.evidence);
        return uint256(klerosItemID);
    }

    /**
     * @notice After the review period ends, the items on the tcr list should be claimed using this function
     * returns the badge's mint callee deposit and set the internal value to 0 again
     * the internal value is not the deposit, is just a counter to know how much money belongs to the deposit
     * this method can be called by anyone
     * @param badgeId the klerosBadgeId
     */
    function claim(uint256 badgeId, bytes calldata /*data*/, address /*caller*/) public onlyTheBadge returns (address) {
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);

        // This changes the state of the item from Requested to Accepted and returns the deposit to our contract
        lightGeneralizedTCR.executeRequest(_klerosBadge.itemID);

        // If this contract (KlerosBadgeModelController) didn't received the deposit, we throw an error
        if (_klerosBadge.deposit > address(this).balance) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__claimBadge_insufficientBalance();
        }

        uint256 balanceToDeposit = _klerosBadge.deposit;
        klerosBadgeModelControllerStore.clearKlerosBadgeDepositAmount(badgeId);
        // Then we return the deposit from within our contract to the callee address
        // TODO: review if this is safe enough
        (bool badgeDepositSent, ) = payable(_klerosBadge.callee).call{ value: balanceToDeposit }("");
        if (badgeDepositSent == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__depositReturnFailed();
        }
        emit DepositReturned(_klerosBadge.callee, balanceToDeposit, badgeId);
        return _klerosBadge.destinationAddress;
    }

    /**
     * @notice Given a badge and the evidenceHash, submits a challenge against the controller
     * @param badgeId the id of the badge
     * @param data encoded evidenceHash ipfs hash containing the evidence to generate the challenge
     */
    function challenge(uint256 badgeId, bytes calldata data, address caller) external payable onlyTheBadge {
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);

        if (_klerosBadge.initialized == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        KlerosBadgeModelControllerStore.AddEvidenceParams memory evidenceHash = abi.decode(
            data,
            (KlerosBadgeModelControllerStore.AddEvidenceParams)
        );
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        lightGeneralizedTCR.challengeRequest{ value: (msg.value) }(_klerosBadge.itemID, evidenceHash.evidence);
        emit KlerosBadgeChallenged(badgeId, caller, evidenceHash.evidence);
    }

    /**
     * @notice Given a badge and the evidenceHash, submits a removal request against the controller
     * @param badgeId the id of the badge
     * @param data encoded evidenceHash ipfs hash containing the evidence to generate the removal request
     */
    function removeItem(uint256 badgeId, bytes calldata data, address caller) external payable onlyTheBadge {
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);

        if (_klerosBadge.initialized == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        KlerosBadgeModelControllerStore.AddEvidenceParams memory evidenceHash = abi.decode(
            data,
            (KlerosBadgeModelControllerStore.AddEvidenceParams)
        );
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        lightGeneralizedTCR.removeItem{ value: (msg.value) }(_klerosBadge.itemID, evidenceHash.evidence);
        emit KlerosBadgeChallenged(badgeId, caller, evidenceHash.evidence);
    }

    /**
     * @notice Given a badge and the evidenceHash, adds more evidence to a case
     * @param badgeId the id of the badge
     * @param data encoded evidenceHash ipfs hash adding more evidence to a submission
     */
    function submitEvidence(uint256 badgeId, bytes calldata data, address caller) external onlyTheBadge {
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);

        if (_klerosBadge.initialized == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        KlerosBadgeModelControllerStore.AddEvidenceParams memory evidenceHash = abi.decode(
            data,
            (KlerosBadgeModelControllerStore.AddEvidenceParams)
        );
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        lightGeneralizedTCR.submitEvidence(_klerosBadge.itemID, evidenceHash.evidence);
        emit KlerosChallengeEvidenceAdded(badgeId, caller, evidenceHash.evidence);
    }

    /**
     * @notice Creates a request to verify an user in kleros
     * @param _user address of the user
     * @param userMetadata IPFS uri with the metadata of the user to verify
     * @param evidenceUri IPFS uri with the evidence required for the verification
     */
    function submitUserVerification(
        address _user,
        string memory userMetadata,
        string memory evidenceUri
    ) public onlyTheBadgeUsers {
        KlerosBadgeModelControllerStore.KlerosUser memory _klerosUser = klerosBadgeModelControllerStore.getKlerosUser(
            _user
        );

        if (_klerosUser.initialized) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__user__userVerificationAlreadyStarted();
        }

        _klerosUser.initialized = true;
        _klerosUser.verificationStatus = LibKlerosBadgeModelController.VerificationStatus.VerificationSubmitted;
        _klerosUser.userMetadata = userMetadata;
        _klerosUser.verificationEvidence = evidenceUri;

        klerosBadgeModelControllerStore.registerKlerosUser(_user, _klerosUser);
    }

    /**
     * @notice Executes the request to verify an user in kleros
     * @param _user address of the user
     * @param verify true if the user should be verified, otherwise false
     */
    function executeUserVerification(
        address _user,
        bool verify
    ) public onlyTheBadgeUsers onlyUserOnVerification(_user) {
        KlerosBadgeModelControllerStore.KlerosUser memory _klerosUser = klerosBadgeModelControllerStore.getKlerosUser(
            _user
        );
        if (!_klerosUser.initialized) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__user__userNotFound();
        }

        LibKlerosBadgeModelController.VerificationStatus _verificationStatus = verify
            ? LibKlerosBadgeModelController.VerificationStatus.Verified
            : LibKlerosBadgeModelController.VerificationStatus.VerificationRejected;
        klerosBadgeModelControllerStore.updateKlerosUserVerificationStatus(_user, _verificationStatus);
    }

    /**
     * @notice Returns the cost for minting a badge for a kleros controller, its the result of doing klerosBaseDeposit + klerosArbitrationCost
     * @param badgeModelId the badgeModelId
     */
    function mintValue(uint256 badgeModelId) public view returns (uint256) {
        KlerosBadgeModelControllerStore.KlerosBadgeModel memory _klerosBadgeModel = klerosBadgeModelControllerStore
            .getKlerosBadgeModel(badgeModelId);

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);

        IArbitrator _arbitrator = klerosBadgeModelControllerStore.getArbitrator();
        uint256 arbitrationCost = _arbitrator.arbitrationCost(lightGeneralizedTCR.arbitratorExtraData());
        uint256 baseDeposit = lightGeneralizedTCR.submissionBaseDeposit();

        return arbitrationCost + baseDeposit;
    }

    /**
     * @notice Returns true if the controller supports to be the temporal owner of the minted badge until the user claims it
     */
    function isMintableToController(uint256 /*badgeModelId*/, address /*account*/) public pure returns (bool) {
        return false;
    }

    /**
     * @notice Returns true if the badge is ready to be claimed (its status is RegistrationRequested and the challenge period ended), otherwise returns false
     * @param badgeId the klerosBadgeId
     */
    function isClaimable(uint256 badgeId) public view returns (bool) {
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);

        if (_klerosBadge.initialized == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
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
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);

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
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);

        if (_klerosBadge.initialized == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        if (_klerosBadge.itemID == 0) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
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

        revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__notInChallengeableStatus();
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
     * @notice returns the current configured user verification fee
     */
    function getVerifyUserProtocolFee() public view returns (uint256) {
        return klerosBadgeModelControllerStore.getVerifyUserProtocolFee();
    }

    /**
     * @notice returns true if the given userAddress exists and has been verified, otherwise returns false.
     * @param _user the userAddress
     */
    function isUserVerified(address _user) public view returns (bool) {
        KlerosBadgeModelControllerStore.KlerosUser memory _klerosUser = klerosBadgeModelControllerStore.getKlerosUser(
            _user
        );
        if (_klerosUser.initialized == false) {
            return false;
        }
        if (_klerosUser.verificationStatus == LibKlerosBadgeModelController.VerificationStatus.Verified) {
            return true;
        }
        return false;
    }

    /**
     * @notice Internal function that returns the TCR contract instance for a given klerosBadgeModel
     * @param badgeId the klerosBadgeId
     */
    function getLightGeneralizedTCR(uint256 badgeId) internal view returns (ILightGeneralizedTCR) {
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);
        KlerosBadgeModelControllerStore.KlerosBadgeModel memory _klerosBadgeModel = klerosBadgeModelControllerStore
            .getKlerosBadgeModel(_klerosBadge.badgeModelId);
        if (_klerosBadgeModel.tcrList == address(0)) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__tcrKlerosBadgeNotFound();
        }
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);
        return lightGeneralizedTCR;
    }

    /**
     * @notice Internal function that the current arbitration cost of a request for the given badgeId
     * @param badgeId the klerosBadgeId
     */
    function getBadgeIdArbitrationCosts(uint256 badgeId) internal view returns (uint256) {
        KlerosBadgeModelControllerStore.KlerosBadge memory _klerosBadge = klerosBadgeModelControllerStore
            .getKlerosBadge(badgeId);
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        (, , uint120 requestCount) = lightGeneralizedTCR.items(_klerosBadge.itemID);
        uint256 lastRequestIndex = requestCount - 1;

        (, , , , , , , , bytes memory requestArbitratorExtraData, ) = lightGeneralizedTCR.getRequestInfo(
            _klerosBadge.itemID,
            lastRequestIndex
        );

        IArbitrator _arbitrator = klerosBadgeModelControllerStore.getArbitrator();
        return _arbitrator.arbitrationCost(requestArbitratorExtraData);
    }

    /**
     * =========================
     * Overrides
     * =========================
     */
    /// Required by the OZ UUPS module
    // solhint-disable-next-line
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}
