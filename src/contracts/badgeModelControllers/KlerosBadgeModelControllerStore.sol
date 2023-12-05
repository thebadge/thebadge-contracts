// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { IArbitrator } from "../../../lib/erc-792/contracts/IArbitrator.sol";
import { CappedMath } from "../../utils/CappedMath.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { LibKlerosBadgeModelController } from "../libraries/LibKlerosBadgeModelController.sol";
import { LibTheBadgeUsers } from "../libraries/LibTheBadgeUsers.sol";
import { TheBadgeRoles } from "../thebadge/TheBadgeRoles.sol";

contract KlerosBadgeModelControllerStore is OwnableUpgradeable, TheBadgeRoles {
    using CappedMath for uint256;

    /**
     * =========================
     * Events
     * =========================
     */
    // Event to log when a contract is added to the list
    event ContractAdded(string indexed _contractName, address indexed contractAddress);

    // Event to log when a contract is removed from the list
    event ContractRemoved(string indexed _contractName, address indexed contractAddress);

    // Event to log when a contract address is updated from the list
    event ContractUpdated(string indexed _contractName, address indexed contractAddress);

    /**
     * =========================
     * Modifiers
     * =========================
     */

    // Modifier to check if the caller is one of the allowedContractAddresses contracts
    modifier onlyPermittedContract() {
        if (allowedContractAddresses[_msgSender()] == false) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__store_OperationNotPermitted();
        }

        _;
    }

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

    struct UserVerification {
        address user;
        string userMetadata;
        string verificationEvidence;
        LibTheBadgeUsers.VerificationStatus verificationStatus;
        address verificationController;
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

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address _arbitrator, address _tcrFactory) public initializer {
        __Ownable_init(admin);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        arbitrator = IArbitrator(_arbitrator);
        tcrFactory = _tcrFactory;
        verifyUserProtocolFee = uint256(0);
    }

    /**
     * =========================
     * Getters
     * =========================
     */
    /**
     * @notice Get the current verification protocol fee.
     * @return The current verification protocol fee.
     */
    function getVerifyUserProtocolFee() external view returns (uint256) {
        return verifyUserProtocolFee;
    }

    /**
     * @notice Get KlerosBadgeModel by badge model ID.
     * @param badgeModelId The ID of the KlerosBadgeModel.
     * @return KlerosBadgeModel struct representing the badge model.
     */
    function getKlerosBadgeModel(uint256 badgeModelId) external view returns (KlerosBadgeModel memory) {
        return klerosBadgeModels[badgeModelId];
    }

    /**
     * @notice Get KlerosBadge by badge ID.
     * @param badgeId The ID of the KlerosBadge.
     * @return KlerosBadge struct representing the badge.
     */
    function getKlerosBadge(uint256 badgeId) external view returns (KlerosBadge memory) {
        return klerosBadges[badgeId];
    }

    /**
     * @notice Get the current arbitrator contract.
     * @return The current IArbitrator contract.
     */
    function getArbitrator() external view returns (IArbitrator) {
        return arbitrator;
    }

    /**
     * @notice Get the current TCR factory address.
     * @return The current TCR factory address.
     */
    function getTCRFactory() external view returns (address) {
        return tcrFactory;
    }

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

    // Function to add a contract to the list of permitted contracts
    function addPermittedContract(
        string memory _contractName,
        address _contractAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_contractAddress == address(0)) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__store_InvalidContractAddress();
        }

        // Check if the contract name already exists
        if (allowedContractAddressesByContractName[_contractName] != address(0)) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__store_ContractNameAlreadyExists();
        }

        // Add the contract name and address to the mapping
        allowedContractAddressesByContractName[_contractName] = _contractAddress;
        allowedContractAddresses[_contractAddress] = true;

        emit ContractAdded(_contractName, _contractAddress);
    }

    // Function to remove a contract from the list of permitted contracts
    function removePermittedContract(string memory _contractName) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address contractAddress = allowedContractAddressesByContractName[_contractName];

        // Check if the contract name exists in the mapping
        if (contractAddress == address(0)) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__store_InvalidContractName();
        }

        // Remove the contract name and address from the mapping
        delete allowedContractAddressesByContractName[_contractName];
        delete allowedContractAddresses[contractAddress];

        emit ContractRemoved(_contractName, contractAddress);
    }

    // Function to update a contract address based on the contract name
    function updatePermittedContract(
        string memory _contractName,
        address _newContractAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newContractAddress == address(0)) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__store_InvalidContractAddress();
        }

        // Check if the contract name exists in the mapping
        address oldContractAddress = allowedContractAddressesByContractName[_contractName];
        if (oldContractAddress == address(0)) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__store_InvalidContractName();
        }

        // Update the contract address associated with the contract name
        delete allowedContractAddresses[oldContractAddress];
        allowedContractAddressesByContractName[_contractName] = _newContractAddress;
        allowedContractAddresses[_newContractAddress] = true;

        emit ContractUpdated(_contractName, _newContractAddress);
    }

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
    ) external onlyPermittedContract {
        KlerosBadgeModel storage badgeModel = klerosBadgeModels[_badgeModelId];

        if (badgeModel.initialized == true) {
            revert LibKlerosBadgeModelController
                .KlerosBadgeModelController__createBadgeModel_badgeModelAlreadyCreated();
        }

        KlerosBadgeModel memory newBadgeModel = KlerosBadgeModel({
            owner: _owner,
            badgeModelId: _badgeModelId,
            tcrList: _tcrList,
            governor: _governor,
            admin: _admin,
            initialized: true
        });

        klerosBadgeModels[_badgeModelId] = newBadgeModel;
        klerosBadgeModelIdsCounter++;
    }

    /**
     * @notice Update a KlerosBadgeModel.
     * @param badgeModelId The ID of the KlerosBadgeModel to update.
     * @param _klerosBadgeModel the model updated
     */
    function updateKlerosBadgeModel(
        uint256 badgeModelId,
        KlerosBadgeModel memory _klerosBadgeModel
    ) external onlyPermittedContract {
        KlerosBadgeModel storage badgeModel = klerosBadgeModels[badgeModelId];

        if (badgeModel.owner == address(0)) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badgeModel__NotFound();
        }

        klerosBadgeModels[badgeModelId] = _klerosBadgeModel;
    }

    /**
     * @notice Add a new KlerosBadge.
     * @param badgeId The ID of the KlerosBadge.
     * @param badge The KlerosBadge struct to be added.
     */
    function addKlerosBadge(uint256 badgeId, KlerosBadge memory badge) external onlyPermittedContract {
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
    function clearKlerosBadgeDepositAmount(uint256 badgeId) external onlyPermittedContract {
        KlerosBadge storage existingBadge = klerosBadges[badgeId];

        if (!existingBadge.initialized) {
            revert LibKlerosBadgeModelController.KlerosBadgeModelController__badge__klerosBadgeNotFound();
        }

        existingBadge.deposit = 0;
    }

    /**
     * @notice Update the verification protocol fee.
     * @dev Only the owner can update the verification protocol fee.
     * @param newFee The new verification protocol fee to set.
     */
    function setVerifyUserProtocolFee(uint256 newFee) external onlyPermittedContract {
        verifyUserProtocolFee = newFee;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
