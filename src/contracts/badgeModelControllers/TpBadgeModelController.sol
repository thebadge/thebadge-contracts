// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "../../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../../interfaces/ILightGTCRFactory.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { TheBadge } from "../thebadge/TheBadge.sol";
import { TheBadgeModels } from "../thebadge/TheBadgeModels.sol";
import { TheBadgeUsers } from "../thebadge/TheBadgeUsers.sol";
import { TheBadgeRoles } from "../thebadge/TheBadgeRoles.sol";
import { CappedMath } from "../../utils/CappedMath.sol";
import { IArbitrator } from "../../../lib/erc-792/contracts/IArbitrator.sol";
import { TpBadgeModelControllerStore } from "./TpBadgeModelControllerStore.sol";
import { LibTpBadgeModelController } from "../libraries/LibTpBadgeModelController.sol";

contract TpBadgeModelController is Initializable, UUPSUpgradeable, TheBadgeRoles, IBadgeModelController {
    TpBadgeModelControllerStore private _tpBadgeModelStore;
    TheBadge public theBadge;
    TheBadgeModels public theBadgeModels;
    TheBadgeUsers public theBadgeUsers;
    using CappedMath for uint256;

    /**
     * =========================
     * Events
     * =========================
     */
    event Initialize(address indexed admin);
    event NewThirdPartyBadgeModel(uint256 indexed badgeModelId, address indexed tcrAddress);
    event ThirdPartyBadgeMinted(uint256 indexed badgeId, bytes32 indexed tcrItemId);
    event ThirdPartyBadgeClaimed(
        address indexed originAddress,
        address indexed recipientAddress,
        uint256 indexed badgeId
    );
    event ProtocolSettingsUpdated();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyTheBadge() {
        if (address(theBadge) != msg.sender) {
            revert LibTpBadgeModelController.ThirdPartyModelController__onlyTheBadge_senderNotTheBadge();
        }
        _;
    }

    modifier onlyTheBadgeModels() {
        if (address(theBadgeModels) != msg.sender) {
            revert LibTpBadgeModelController.ThirdPartyModelController__onlyTheBadge_senderNotTheBadgeModels();
        }
        _;
    }

    modifier onlyTheBadgeUsers() {
        if (address(theBadgeUsers) != msg.sender) {
            revert LibTpBadgeModelController.ThirdPartyModelController__onlyTheBadge_senderNotTheBadgeUsers();
        }
        _;
    }

    modifier onlyClaimer(address caller) {
        if (!hasRole(CLAIMER_ROLE, caller)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__claimBadge_notAllowed();
        }
        _;
    }

    modifier onlyUserOnVerification(address _user) {
        TpBadgeModelControllerStore.ThirdPartyUser memory _thirdPartyUser = _tpBadgeModelStore.getUser(_user);
        if (_thirdPartyUser.initialized == false) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userNotFound();
        }
        if (_thirdPartyUser.verificationStatus != LibTpBadgeModelController.VerificationStatus.VerificationSubmitted) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userVerificationNotStarted();
        }
        _;
    }

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
        address tpBadgeModelStore
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        theBadge = TheBadge(payable(_theBadge));
        theBadgeModels = TheBadgeModels(payable(_theBadgeModels));
        theBadgeUsers = TheBadgeUsers(payable(_theBadgeUsers));
        _tpBadgeModelStore = TpBadgeModelControllerStore(payable(tpBadgeModelStore));
        emit Initialize(admin);
    }

    /**
     * @notice Allows to create off-chain third-party strategies for registered entities
     * @param badgeModelId from TheBadge contract
     */
    function createBadgeModel(uint256 badgeModelId, bytes calldata /*data*/) public onlyTheBadgeModels {
        TpBadgeModelControllerStore.ThirdPartyBadgeModel memory _badgeModel = _tpBadgeModelStore.getBadgeModel(
            badgeModelId
        );
        if (_badgeModel.tcrList != address(0)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__createBadgeModel_badgeModelAlreadyCreated();
        }

        ILightGTCRFactory lightGTCRFactory = ILightGTCRFactory(_tpBadgeModelStore.tcrFactory());
        uint256 thirdPartyBaseDeposit = LibTpBadgeModelController.THIRD_PARTY_BASE_DEPOSIT;
        uint256 thirdPartyStakeMultiplier = LibTpBadgeModelController.THIRD_PARTY_STAKE_MULTIPLIER;
        lightGTCRFactory.deploy(
            IArbitrator(address(_tpBadgeModelStore.arbitrator())), // Arbitrator address
            bytes.concat(
                abi.encodePacked(LibTpBadgeModelController.COURT_ID),
                abi.encodePacked(LibTpBadgeModelController.NUMBER_OF_JURORS)
            ), // ArbitratorExtraData
            address(0), // TODO: check this. The address of the TCR that stores related TCR addresses. This parameter can be left empty.
            LibTpBadgeModelController.REGISTRATION_META_EVIDENCE, // The URI of the meta evidence object for registration requests.
            LibTpBadgeModelController.CLEARING_META_EVIDENCE, // The URI of the meta evidence object for clearing requests.
            address(this), // The trusted governor of this contract.
            // The base deposits for requests/challenges (4 values: submit, remove, challenge and removal request)
            [thirdPartyBaseDeposit, thirdPartyBaseDeposit, thirdPartyBaseDeposit, thirdPartyBaseDeposit],
            LibTpBadgeModelController.CHALLENGE_TIME_SECONDS, // The time in seconds parties have to challenge a request.
            [thirdPartyStakeMultiplier, thirdPartyStakeMultiplier, thirdPartyStakeMultiplier], // Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR)
            address(this) // The address of the relay contract to add/remove items directly.
        );

        // Get the address for the TCR created
        uint256 index = lightGTCRFactory.count() - 1;
        address tcrListAddress = address(lightGTCRFactory.instances(index));
        if (tcrListAddress == address(0)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__createBadgeModel_TCRListAddressZero();
        }

        TpBadgeModelControllerStore.ThirdPartyBadgeModel memory _newBadgeModel = TpBadgeModelControllerStore
            .ThirdPartyBadgeModel(tcrListAddress);
        _tpBadgeModelStore.addBadgeModel(_newBadgeModel);

        emit NewThirdPartyBadgeModel(badgeModelId, tcrListAddress);
    }

    /**
     * @notice adds a new badge directly to the tcr list
     * @param badgeModelId the badgeModelId
     * @param badgeId the badgeId
     * @param data extra data related to the badge, usually 0x
     */
    function mint(
        address /*callee*/,
        uint256 badgeModelId,
        uint256 badgeId,
        bytes calldata data,
        address /*destinationAddress*/
    ) public payable onlyTheBadge returns (uint256) {
        uint256 mintCost = this.mintValue(badgeModelId);
        if (msg.value != mintCost) {
            revert LibTpBadgeModelController.ThirdPartyModelController__mintBadge_wrongValue();
        }

        TpBadgeModelControllerStore.ThirdPartyBadgeModel memory _badgeModel = _tpBadgeModelStore.getBadgeModel(
            badgeModelId
        );
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_badgeModel.tcrList);
        TpBadgeModelControllerStore.MintParams memory args = abi.decode(data, (TpBadgeModelControllerStore.MintParams));

        lightGeneralizedTCR.addItemDirectly(args.badgeDataUri);

        // Calculates which is the itemID inside the TCR list
        // Its needed on the subgraph to check the disputes status for that item
        bytes32 tcrItemID = keccak256(abi.encodePacked(args.badgeDataUri));

        TpBadgeModelControllerStore.ThirdPartyBadge memory _newBadge = TpBadgeModelControllerStore.ThirdPartyBadge(
            tcrItemID,
            badgeModelId,
            badgeId,
            true
        );
        _tpBadgeModelStore.addBadge(badgeId, _newBadge);
        emit ThirdPartyBadgeMinted(badgeId, tcrItemID);
        return uint256(tcrItemID);
    }

    /**
     * @notice moves a badge from the controller to the final recipient address
     * @param badgeId the id of the badge
     * @param data contains the recipient address
     */
    function claim(uint256 badgeId, bytes calldata data) public onlyTheBadge returns (address) {
        TpBadgeModelControllerStore.ClaimParams memory args = abi.decode(
            data,
            (TpBadgeModelControllerStore.ClaimParams)
        );
        theBadge.safeTransferFrom(address(this), args.recipientAddress, badgeId, 1, "0x");
        emit ThirdPartyBadgeClaimed(address(this), args.recipientAddress, badgeId);
        return args.recipientAddress;
    }

    // Should not be implemented
    function challenge(uint256 /*badgeId*/, bytes calldata /*data*/) external payable {
        revert LibTpBadgeModelController.ThirdPartyModelController__method_not_supported();
    }

    // Should remove the item directly from the user and from the tcr list
    function removeItem(uint256 /*badgeId*/, bytes calldata /*data*/) external payable {
        // TOOD: IMPLEMENT
        revert LibTpBadgeModelController.ThirdPartyModelController__method_not_supported();
    }

    // Should not be implemented
    function submitEvidence(uint256 /*badgeId*/, bytes calldata /*data*/) external pure {
        revert LibTpBadgeModelController.ThirdPartyModelController__method_not_supported();
    }

    // Write methods
    function submitUserVerification(
        address _user,
        string memory userMetadata,
        string memory evidenceUri
    ) public onlyTheBadgeUsers {
        TpBadgeModelControllerStore.ThirdPartyUser memory _tpUser = _tpBadgeModelStore.getUser(_user);

        if (_tpUser.initialized) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userVerificationAlreadyStarted();
        }

        _tpUser.initialized = true;
        _tpUser.verificationStatus = LibTpBadgeModelController.VerificationStatus.VerificationSubmitted;
        _tpUser.userMetadata = userMetadata;
        _tpUser.verificationEvidence = evidenceUri;
        _tpBadgeModelStore.updateUser(_user, _tpUser);
    }

    /**
     * @notice Executes the request to verify an user
     * @param _user address of the user
     * @param verify true if the user should be verified, otherwise false
     */
    function executeUserVerification(
        address _user,
        bool verify
    ) public onlyTheBadgeUsers onlyUserOnVerification(_user) {
        TpBadgeModelControllerStore.ThirdPartyUser memory _tpUser = _tpBadgeModelStore.getUser(_user);
        _tpUser.verificationStatus = verify
            ? LibTpBadgeModelController.VerificationStatus.Verified
            : LibTpBadgeModelController.VerificationStatus.VerificationRejected;
        _tpBadgeModelStore.updateUser(_user, _tpUser);
    }

    /*
     * @notice Updates the value of the protocol: _verifyUserProtocolFee
     * @param _verifyUserProtocolFee the default fee that TheBadge protocol charges for each user verification (in bps)
     */
    function updateVerifyUserProtocolFee(uint256 _verifyUserProtocolFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _tpBadgeModelStore.updateVerifyUserProtocolFee(_verifyUserProtocolFee);
        emit ProtocolSettingsUpdated();
    }

    /*
     * @notice Returns the cost to mint a third-party badge
     */
    function mintValue(uint256 /*badgeModelId*/) external pure returns (uint256) {
        return 0;
    }

    /**
     * @notice Returns true if the controller supports to be the temporal owner of the minted badge until the user claims it
     */
    function isMintableToController(uint256 /*badgeModelId*/, address /*account*/) public pure returns (bool) {
        return true;
    }

    /**
     * @notice Returns true if the badge is ready to be claimed to the destination address, otherwise returns false
     * @param badgeId the badgeId
     */
    function isClaimable(uint256 badgeId, bytes calldata data, address /*caller*/) external view returns (bool) {
        TpBadgeModelControllerStore.ClaimParams memory args = abi.decode(
            data,
            (TpBadgeModelControllerStore.ClaimParams)
        );
        if (args.recipientAddress == address(0)) {
            return false;
        }
        uint256 ownBalance = theBadge.balanceOf(address(this), badgeId);
        if (ownBalance > 0) {
            return true;
        }
        return false;
    }

    /**
     * @notice Checks the status of the badge within the TCR list, returns true if the status is (1 = registered or 3 = clearing/removal requested)
     * It returns false for the other statuses (0 = absent; 2 = registration requested)
     * @param badgeId the badgeId
     */
    function isAssetActive(uint256 badgeId) public view returns (bool) {
        ILightGeneralizedTCR lightGeneralizedTCR = getLightGeneralizedTCR(badgeId);
        TpBadgeModelControllerStore.ThirdPartyBadge memory _tpBadge = _tpBadgeModelStore.getBadge(badgeId);

        (uint8 itemStatus, , ) = lightGeneralizedTCR.getItemInfo(_tpBadge.itemID);
        // The status is REGISTERED or ClearingRequested
        if (itemStatus == 1 || itemStatus == 3) {
            return true;
        }

        return false;
    }

    /**
     * @notice not implemented / not used here
     */
    function getChallengeDepositValue(uint256 /*badgeId*/) external pure returns (uint256) {
        revert LibTpBadgeModelController.ThirdPartyModelController__method_not_supported();
    }

    /**
     * @notice not implemented / not used here
     */
    function getRemovalDepositValue(uint256 /*badgeId*/) external pure returns (uint256) {
        revert LibTpBadgeModelController.ThirdPartyModelController__method_not_supported();
    }

    /**
     * @notice returns the current configured third-party user verification fee
     */
    function getVerifyUserProtocolFee() external view returns (uint256) {
        return _tpBadgeModelStore.verifyUserProtocolFee();
    }

    /**
     * @notice returns true if the given userAddress exists and has been verified, otherwise returns false.
     * @param _user the userAddress
     */
    function isUserVerified(address _user) external view returns (bool) {
        TpBadgeModelControllerStore.ThirdPartyUser memory _tpUser = _tpBadgeModelStore.getUser(_user);
        if (_tpUser.initialized == false) {
            return false;
        }
        if (_tpUser.verificationStatus == LibTpBadgeModelController.VerificationStatus.Verified) {
            return true;
        }
        return false;
    }

    /**
     * @notice Internal function that returns the TCR contract instance for a given badgeId
     * @param badgeId the badgeId
     */
    function getLightGeneralizedTCR(uint256 badgeId) internal view returns (ILightGeneralizedTCR) {
        address tcrList = _tpBadgeModelStore.getBadgeTcrList(badgeId);
        if (tcrList == address(0)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__badge__tcrKlerosBadgeNotFound();
        }
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(tcrList);
        return lightGeneralizedTCR;
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
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}