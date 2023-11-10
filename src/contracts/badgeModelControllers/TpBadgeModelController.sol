// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { ILightGeneralizedTCR } from "../../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../../interfaces/ILightGTCRFactory.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { TheBadge } from "../thebadge/TheBadge.sol";
import { TheBadgeModels } from "../thebadge/TheBadgeModels.sol";
import { TheBadgeUsers } from "../thebadge/TheBadgeUsers.sol";
import { TheBadgeRoles } from "../thebadge/TheBadgeRoles.sol";
import { CappedMath } from "../../utils/CappedMath.sol";
import { IArbitrator } from "../../../lib/erc-792/contracts/IArbitrator.sol";
import { TpBadgeModelControllerStore } from "./TpBadgeModelControllerStore.sol";
import { LibTpBadgeModelController } from "../libraries/LibTpBadgeModelController.sol";

contract TpBadgeModelController is
    Initializable,
    UUPSUpgradeable,
    TheBadgeRoles,
    IBadgeModelController,
    ERC1155HolderUpgradeable
{
    using CappedMath for uint256;
    TpBadgeModelControllerStore public tpBadgeModelControllerStore;
    TheBadge public theBadge;
    TheBadgeModels public theBadgeModels;
    TheBadgeUsers public theBadgeUsers;

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

    modifier onlyUserOnVerification(address _user) {
        TpBadgeModelControllerStore.ThirdPartyUser memory _thirdPartyUser = tpBadgeModelControllerStore.getUser(_user);
        if (_thirdPartyUser.initialized == false) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userNotFound();
        }
        if (_thirdPartyUser.verificationStatus != LibTpBadgeModelController.VerificationStatus.VerificationSubmitted) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userVerificationNotStarted();
        }
        _;
    }

    modifier onlyThirdPartyUser(address callee) {
        TpBadgeModelControllerStore.ThirdPartyUser memory _thirdPartyUser = tpBadgeModelControllerStore.getUser(callee);
        if (_thirdPartyUser.initialized == false) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userNotFound();
        }
        if (_thirdPartyUser.verificationStatus != LibTpBadgeModelController.VerificationStatus.Verified) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userVerificationRejected();
        }
        _;
    }

    modifier onlyBadgeModelAdministrator(uint256 badgeModelId, address callee) {
        bool isOwner = tpBadgeModelControllerStore.isBadgeModelOwner(badgeModelId, callee);
        if (!isOwner) {
            bool isAdministrator = tpBadgeModelControllerStore.isBadgeModelAdministrator(badgeModelId, callee);
            if (!isAdministrator) {
                revert LibTpBadgeModelController.ThirdPartyModelController__store_OperationNotPermitted();
            }
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
        address _tpBadgeModelStore
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        theBadge = TheBadge(payable(_theBadge));
        theBadgeModels = TheBadgeModels(payable(_theBadgeModels));
        theBadgeUsers = TheBadgeUsers(payable(_theBadgeUsers));
        tpBadgeModelControllerStore = TpBadgeModelControllerStore(payable(_tpBadgeModelStore));
        emit Initialize(admin);
    }

    /**
     * @notice Allows to create off-chain third-party strategies for registered entities
     * @param callee the user that originally called the createBadgeModel() function
     * @param badgeModelId from TheBadge contract
     * @param data contains the encoded value: administrators of the badgeModel

     */
    function createBadgeModel(
        address callee,
        uint256 badgeModelId,
        bytes calldata data
    ) public onlyTheBadgeModels onlyThirdPartyUser(callee) {
        uint256 _badgeModelId = badgeModelId;
        address _callee = callee;
        bytes calldata _data = data;
        TpBadgeModelControllerStore.ThirdPartyBadgeModel memory _badgeModel = tpBadgeModelControllerStore.getBadgeModel(
            _badgeModelId
        );
        if (_badgeModel.tcrList != address(0)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__createBadgeModel_badgeModelAlreadyCreated();
        }

        TpBadgeModelControllerStore.CreateBadgeModel memory args = abi.decode(
            _data,
            (TpBadgeModelControllerStore.CreateBadgeModel)
        );

        ILightGTCRFactory lightGTCRFactory = ILightGTCRFactory(tpBadgeModelControllerStore.tcrFactory());
        uint256 thirdPartyBaseDeposit = LibTpBadgeModelController.THIRD_PARTY_BASE_DEPOSIT;
        uint256 thirdPartyStakeMultiplier = LibTpBadgeModelController.THIRD_PARTY_STAKE_MULTIPLIER;
        address _admin = address(this);
        address _governor = address(this);
        lightGTCRFactory.deploy(
            IArbitrator(address(tpBadgeModelControllerStore.arbitrator())), // Arbitrator address
            bytes.concat(
                abi.encodePacked(LibTpBadgeModelController.COURT_ID),
                abi.encodePacked(LibTpBadgeModelController.NUMBER_OF_JURORS)
            ), // ArbitratorExtraData
            address(0), // TODO: check this. The address of the TCR that stores related TCR addresses. This parameter can be left empty.
            LibTpBadgeModelController.REGISTRATION_META_EVIDENCE, // The URI of the meta evidence object for registration requests.
            LibTpBadgeModelController.CLEARING_META_EVIDENCE, // The URI of the meta evidence object for clearing requests.
            _governor, // The governor of the TCR list, it's allowed to update the tcr parameters
            // The base deposits for requests/challenges (4 values: submit, remove, challenge and removal request)
            [thirdPartyBaseDeposit, thirdPartyBaseDeposit, thirdPartyBaseDeposit, thirdPartyBaseDeposit],
            LibTpBadgeModelController.CHALLENGE_TIME_SECONDS, // The time in seconds parties have to challenge a request.
            [thirdPartyStakeMultiplier, thirdPartyStakeMultiplier, thirdPartyStakeMultiplier], // Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR)
            _admin // The address of the relay contract that's allowed add/remove items directly.
        );

        // Get the address for the TCR created
        uint256 index = lightGTCRFactory.count() - 1;
        address tcrListAddress = address(lightGTCRFactory.instances(index));
        if (tcrListAddress == address(0)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__createBadgeModel_TCRListAddressZero();
        }

        TpBadgeModelControllerStore.ThirdPartyBadgeModel memory _newBadgeModel = TpBadgeModelControllerStore
            .ThirdPartyBadgeModel(_callee, _badgeModelId, tcrListAddress, _governor, _admin, true);
        tpBadgeModelControllerStore.addBadgeModel(_badgeModelId, _newBadgeModel);
        tpBadgeModelControllerStore.addAdministratorsToBadgeModel(_badgeModelId, args.administrators);

        emit NewThirdPartyBadgeModel(_badgeModelId, tcrListAddress);
    }

    /**
     * @notice adds a new badge directly to the tcr list
     * @param callee the user that originally called the mint() function
     * @param badgeModelId the badgeModelId
     * @param badgeId the badgeId
     * @param data extra data related to the badge, contains the badgeDataUri
     */
    function mint(
        address callee,
        uint256 badgeModelId,
        uint256 badgeId,
        bytes calldata data,
        address /*destinationAddress*/
    ) public payable onlyTheBadge onlyBadgeModelAdministrator(badgeModelId, callee) returns (uint256) {
        uint256 _badgeModelId = badgeModelId;
        uint256 _badgeId = badgeId;
        bytes calldata _data = data;
        uint256 mintCost = this.mintValue(_badgeModelId);
        if (msg.value != mintCost) {
            revert LibTpBadgeModelController.ThirdPartyModelController__mintBadge_wrongValue();
        }

        TpBadgeModelControllerStore.ThirdPartyBadgeModel memory _badgeModel = tpBadgeModelControllerStore.getBadgeModel(
            _badgeModelId
        );
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_badgeModel.tcrList);
        TpBadgeModelControllerStore.MintParams memory args = abi.decode(
            _data,
            (TpBadgeModelControllerStore.MintParams)
        );

        lightGeneralizedTCR.addItemDirectly(args.badgeDataUri);

        // Calculates which is the itemID inside the TCR list
        // Its needed on the subgraph to check the disputes status for that item
        bytes32 tcrItemID = keccak256(abi.encodePacked(args.badgeDataUri));

        TpBadgeModelControllerStore.ThirdPartyBadge memory _newBadge = TpBadgeModelControllerStore.ThirdPartyBadge(
            tcrItemID,
            _badgeModelId,
            _badgeId,
            true
        );
        tpBadgeModelControllerStore.addBadge(_badgeId, _newBadge);
        emit ThirdPartyBadgeMinted(_badgeId, tcrItemID);
        return uint256(tcrItemID);
    }

    /**
     * @notice moves a badge from the controller to the final recipient address
     * @param badgeId the id of the badge
     * @param data contains the recipient address
     * @param caller the address of the user that originally called the claim() function
     */
    function claim(uint256 badgeId, bytes calldata data, address caller) public onlyTheBadge returns (address) {
        TpBadgeModelControllerStore.ClaimParams memory args = abi.decode(
            data,
            (TpBadgeModelControllerStore.ClaimParams)
        );

        if (args.recipientAddress == address(0)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__claimBadge_invalidRecipient();
        }

        uint256 ownBalance = theBadge.balanceOf(address(this), badgeId);
        if (ownBalance == 0) {
            revert LibTpBadgeModelController.ThirdPartyModelController__claimBadge_invalidBadgeOrAlreadyClaimed();
        }

        // This is the role assigned to the relayer
        if (!hasRole(CLAIMER_ROLE, caller)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__claimBadge_userNotAllowed();
        }

        theBadge.safeTransferFrom(address(this), args.recipientAddress, badgeId, 1, "0x");
        emit ThirdPartyBadgeClaimed(address(this), args.recipientAddress, badgeId);
        return args.recipientAddress;
    }

    // Should not be implemented
    function challenge(uint256 /*badgeId*/, bytes calldata /*data*/, address /*caller*/) external payable {
        revert LibTpBadgeModelController.ThirdPartyModelController__method_not_supported();
    }

    // Should remove the item directly from the user and from the tcr list
    function removeItem(uint256 /*badgeId*/, bytes calldata /*data*/, address /*caller*/) external payable {
        // TOOD: IMPLEMENT
        revert LibTpBadgeModelController.ThirdPartyModelController__method_not_supported();
    }

    // Should not be implemented
    function submitEvidence(uint256 /*badgeId*/, bytes calldata /*data*/, address /*caller*/) external pure {
        revert LibTpBadgeModelController.ThirdPartyModelController__method_not_supported();
    }

    // Write methods
    function submitUserVerification(
        address _user,
        string memory userMetadata,
        string memory evidenceUri
    ) public onlyTheBadgeUsers {
        TpBadgeModelControllerStore.ThirdPartyUser memory _tpUser = tpBadgeModelControllerStore.getUser(_user);

        if (_tpUser.initialized) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userVerificationAlreadyStarted();
        }

        _tpUser.initialized = true;
        _tpUser.verificationStatus = LibTpBadgeModelController.VerificationStatus.VerificationSubmitted;
        _tpUser.userMetadata = userMetadata;
        _tpUser.verificationEvidence = evidenceUri;
        tpBadgeModelControllerStore.registerTpUser(_user, _tpUser);
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
        TpBadgeModelControllerStore.ThirdPartyUser memory _tpUser = tpBadgeModelControllerStore.getUser(_user);
        _tpUser.verificationStatus = verify
            ? LibTpBadgeModelController.VerificationStatus.Verified
            : LibTpBadgeModelController.VerificationStatus.VerificationRejected;
        tpBadgeModelControllerStore.updateUser(_user, _tpUser);
    }

    /*
     * @notice Updates the value of the protocol: _verifyUserProtocolFee
     * @param _verifyUserProtocolFee the default fee that TheBadge protocol charges for each user verification (in bps)
     */
    function updateVerifyUserProtocolFee(uint256 _verifyUserProtocolFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tpBadgeModelControllerStore.updateVerifyUserProtocolFee(_verifyUserProtocolFee);
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
     * @notice Returns true if the badge is ready to be claimed to its destination address, otherwise returns false
     * @param badgeId the badgeId
     */
    function isClaimable(uint256 badgeId) external view returns (bool) {
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
        TpBadgeModelControllerStore.ThirdPartyBadge memory _tpBadge = tpBadgeModelControllerStore.getBadge(badgeId);

        (uint8 itemStatus, , ) = lightGeneralizedTCR.getItemInfo(_tpBadge.itemID);
        // The status is REGISTERED or ClearingRequested
        if (itemStatus == 1 || itemStatus == 3) {
            return true;
        }

        return false;
    }

    /**
     * @notice should not be used
     */
    function getChallengeDepositValue(uint256 /*badgeId*/) external pure returns (uint256) {
        return LibTpBadgeModelController.CHALLENGE_COST;
    }

    /**
     * @notice should not be used
     */
    function getRemovalDepositValue(uint256 /*badgeId*/) external pure returns (uint256) {
        return LibTpBadgeModelController.CHALLENGE_COST;
    }

    /**
     * @notice returns the current configured third-party user verification fee
     */
    function getVerifyUserProtocolFee() external view returns (uint256) {
        return tpBadgeModelControllerStore.verifyUserProtocolFee();
    }

    /**
     * @notice returns true if the given userAddress exists and has been verified, otherwise returns false.
     * @param _user the userAddress
     */
    function isUserVerified(address _user) external view returns (bool) {
        TpBadgeModelControllerStore.ThirdPartyUser memory _tpUser = tpBadgeModelControllerStore.getUser(_user);
        if (_tpUser.initialized == false) {
            return false;
        }
        if (_tpUser.verificationStatus == LibTpBadgeModelController.VerificationStatus.Verified) {
            return true;
        }
        return false;
    }

    /**
     * @notice If if this badgeModel can be upgraded or not
     */
    function isBadgeModelMetadataUpgradeable() external pure returns (bool) {
        return true;
    }

    /**
     * @notice If if this badgeModel can be updated or not
     */
    function isBadgeModelMetadataUpdatable() external pure returns (bool) {
        return false;
    }

    /**
     * @notice Internal function that returns the TCR contract instance for a given badgeId
     * @param badgeId the badgeId
     */
    function getLightGeneralizedTCR(uint256 badgeId) internal view returns (ILightGeneralizedTCR) {
        address tcrList = tpBadgeModelControllerStore.getBadgeTcrList(badgeId);
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable, ERC1155HolderUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

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
