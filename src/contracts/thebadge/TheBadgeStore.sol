// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { LibTheBadgeModels } from "../libraries/LibTheBadgeModels.sol";
import { LibTheBadgeModels } from "../libraries/LibTheBadgeModels.sol";
import { LibTheBadgeStore } from "../libraries/LibTheBadgeStore.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TheBadgeStore is TheBadgeRoles, OwnableUpgradeable {
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
            revert LibTheBadgeStore.TheBadge__Store_OperationNotPermitted();
        }

        _;
    }

    uint256 internal badgeModelIdsCounter;
    uint256 internal badgeIdsCounter;
    uint256 public createBadgeModelProtocolFee;
    uint256 public mintBadgeProtocolDefaultFeeInBps;
    address public feeCollector;

    /**
     * =========================
     * Types
     * =========================
     */

    /**
     * @param controller the smart contract that controls a badge model.
     * @param paused if the controller is paused, no operations can be done
     * @param initialized  When the struct is created its true, if the struct was never initialized, its false, used in validations
     */
    struct BadgeModelController {
        address controller;
        bool paused;
        bool initialized;
    }

    /**
     * Struct to use as arg to create a badge model
     */
    struct CreateBadgeModel {
        string metadata;
        string controllerName;
        uint256 mintCreatorFee;
        uint256 validFor;
    }

    /**
     * Struct to store generic information of a badge model.
     */
    struct BadgeModel {
        address creator;
        string controllerName;
        bool paused; // If true it cannot be mintable, configured by the badge model creator
        uint256 mintCreatorFee; // in bps (%). It is taken from mintCreatorFee
        uint256 validFor;
        uint256 mintProtocolFee; // amount that the protocol will charge for this
        bool initialized; // When the struct is created its true, if the struct was never initialized, its false, used in validations
        uint256 version; // The version of the badgeModel, used in case of updates.
        bool suspended; // If true, the badge has been suspended from the administrator of TB contract and users won't be able to interact with anymore
        bool deprecated; // If true, the badge cannot be minted anymore as there is a newer version for this badge, old badges are still valid to maintain backwards compatibility
        string metadata; // The ips hash metadata of the badgeModel
    }

    struct Badge {
        uint256 badgeModelId;
        address account; // The minting address owner of the badge
        uint256 dueDate;
        bool initialized; // When the struct is created its true, if the struct was never initialized, its false, used in validations
    }

    // Mapping to store contract addresses by name
    mapping(address => bool) public allowedContractAddresses;
    mapping(string => address) public allowedContractAddressesByContractName;
    mapping(string => BadgeModelController) public badgeModelControllers;
    mapping(address => BadgeModelController) public badgeModelControllersByAddress;
    mapping(uint256 => BadgeModel) public badgeModels;
    mapping(uint256 => Badge) public badges;
    mapping(uint256 => mapping(address => uint256[])) public userMintedBadgesByBadgeModel;

    uint256 public claimBadgeProtocolFee;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address _feeCollector) public initializer {
        __Ownable_init(admin);
        feeCollector = _feeCollector;
        createBadgeModelProtocolFee = uint256(0);
        mintBadgeProtocolDefaultFeeInBps = uint256(1000); // in bps (= 10%)
        claimBadgeProtocolFee = 0 ether;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * =========================
     * Getters
     * =========================
     */
    function getBadgeModelController(string memory controllerName) external view returns (BadgeModelController memory) {
        return badgeModelControllers[controllerName];
    }

    function getBadgeModelControllerByAddress(
        address controllerAddress
    ) external view returns (BadgeModelController memory) {
        return badgeModelControllersByAddress[controllerAddress];
    }

    function getBadgeModel(uint256 badgeModelId) external view returns (BadgeModel memory) {
        return badgeModels[badgeModelId];
    }

    function getBadge(uint256 badgeId) external view returns (Badge memory) {
        return badges[badgeId];
    }

    function getCurrentBadgeModelsIdCounter() external view returns (uint256) {
        return badgeModelIdsCounter;
    }

    function getCurrentBadgeIdCounter() external view returns (uint256) {
        return badgeIdsCounter;
    }

    function getUserMintedBadgesByBadgeModel(
        uint256 badgeModelId,
        address userAddress
    ) external view returns (uint256[] memory) {
        return userMintedBadgesByBadgeModel[badgeModelId][userAddress];
    }

    /**
     * =========================
     * Setters
     * =========================
     */

    function addBadgeModelController(
        string memory controllerName,
        BadgeModelController calldata badgeModelController
    ) external onlyPermittedContract {
        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];
        if (_badgeModelController.controller != address(0)) {
            revert LibTheBadgeModels.TheBadge__addBadgeModelController_alreadySet();
        }
        badgeModelControllers[controllerName] = badgeModelController;
        badgeModelControllersByAddress[badgeModelController.controller] = badgeModelController;
    }

    function updateBadgeModelController(
        string memory controllerName,
        BadgeModelController calldata badgeModelController
    ) external onlyPermittedContract {
        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];
        if (_badgeModelController.controller == address(0)) {
            revert LibTheBadgeModels.TheBadge__addBadgeModelController_notFound();
        }
        delete badgeModelControllersByAddress[_badgeModelController.controller];
        badgeModelControllers[controllerName] = badgeModelController;
        badgeModelControllersByAddress[badgeModelController.controller] = badgeModelController;
    }

    function addBadgeModel(BadgeModel calldata badgeModel) external onlyPermittedContract {
        badgeModels[badgeModelIdsCounter] = badgeModel;

        badgeModelIdsCounter++;
    }

    function updateBadgeModel(uint256 badgeModelId, BadgeModel calldata badgeModel) external onlyPermittedContract {
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (_badgeModel.initialized == false) {
            revert LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound();
        }

        _badgeModel.mintProtocolFee = badgeModel.mintProtocolFee;
        _badgeModel.mintCreatorFee = badgeModel.mintCreatorFee;
        _badgeModel.paused = badgeModel.paused;
        _badgeModel.deprecated = badgeModel.deprecated;
    }

    function updateBadgeModelMetadata(uint256 badgeModelId, string memory metadata) external onlyPermittedContract {
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (_badgeModel.initialized == false) {
            revert LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound();
        }

        _badgeModel.metadata = metadata;
    }

    function suspendBadgeModel(uint256 badgeModelId, bool suspended) external onlyPermittedContract {
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (_badgeModel.initialized == false) {
            revert LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound();
        }

        _badgeModel.suspended = suspended;
        _badgeModel.metadata = "ipfs://"; // TODO this can be hardcoded to a disabled ipfs hash
    }

    function addBadge(uint256 badgeId, Badge calldata badge) external onlyPermittedContract {
        uint256 _badgeModelId = badge.badgeModelId;
        address _account = badge.account;
        badges[badgeId] = badge;
        userMintedBadgesByBadgeModel[_badgeModelId][_account].push(badgeId);
        badgeIdsCounter++;
    }

    function transferBadge(uint256 badgeId, address origin, address destination) external onlyPermittedContract {
        Badge storage badge = badges[badgeId];
        if (origin == address(0) || destination == address(0)) {
            revert LibTheBadgeStore.TheBadge__Store_InvalidUserAddress();
        }
        if (badge.initialized == false) {
            revert LibTheBadgeStore.TheBadge__Store_InvalidBadgeID();
        }
        if (badge.account != origin) {
            revert LibTheBadgeStore.TheBadge__Store_InvalidUserAddress();
        }

        badge.account = destination;
        uint256[] storage badgeList = userMintedBadgesByBadgeModel[badge.badgeModelId][origin];

        for (uint256 i = 0; i < badgeList.length; i++) {
            if (badgeList[i] == badgeId) {
                uint256 lastIndex = badgeList.length - 1;
                if (i != lastIndex) {
                    // Move the last element to the position of the removed element
                    badgeList[i] = badgeList[lastIndex];
                }
                badgeList.pop(); // Remove the last element
                break;
            }
        }

        userMintedBadgesByBadgeModel[badge.badgeModelId][destination].push(badgeId);
    }

    function updateBadgeDueDate(uint256 badgeId, uint256 dueDate) external onlyPermittedContract {
        Badge storage badge = badges[badgeId];

        if (badge.initialized == false) {
            revert LibTheBadgeStore.TheBadge__Store_InvalidBadgeID();
        }

        badge.dueDate = dueDate;
    }

    /*
     * @notice Updates the value of the protocol: _mintBadgeDefaultFee
     * @param _mintBadgeDefaultFee the default fee that TheBadge protocol charges for each mint (in bps)
     */
    function updateMintBadgeDefaultProtocolFee(uint256 _mintBadgeDefaultFee) public onlyPermittedContract {
        mintBadgeProtocolDefaultFeeInBps = _mintBadgeDefaultFee;
    }

    /*
     * @notice Updates the value of the protocol: _claimProtocolFee
     * @param _claimProtocolFee the fee that TheBadge protocol charges for the claim execution
     */
    function updateClaimBadgeProtocolFee(uint256 _claimProtocolFee) public onlyPermittedContract {
        claimBadgeProtocolFee = _claimProtocolFee;
    }

    /*
     * @notice Updates the value of the protocol: _createBadgeModelValue
     * @param _createBadgeModelValue the default fee that TheBadge protocol charges for each badge model creation (in bps)
     */
    function updateCreateBadgeModelProtocolFee(uint256 _createBadgeModelValue) public onlyPermittedContract {
        createBadgeModelProtocolFee = _createBadgeModelValue;
    }

    // Function to add a contract to the list of permitted contracts
    function addPermittedContract(
        string memory _contractName,
        address _contractAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_contractAddress == address(0)) {
            revert LibTheBadgeStore.TheBadge__Store_InvalidContractAddress();
        }

        // Check if the contract name already exists
        if (allowedContractAddressesByContractName[_contractName] != address(0)) {
            revert LibTheBadgeStore.TheBadge__Store_ContractNameAlreadyExists();
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
            revert LibTheBadgeStore.TheBadge__Store_InvalidContractName();
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
            revert LibTheBadgeStore.TheBadge__Store_InvalidContractAddress();
        }

        // Check if the contract name exists in the mapping
        address oldContractAddress = allowedContractAddressesByContractName[_contractName];
        if (oldContractAddress == address(0)) {
            revert LibTheBadgeStore.TheBadge__Store_InvalidContractName();
        }

        // Update the contract address associated with the contract name
        delete allowedContractAddresses[oldContractAddress];
        allowedContractAddressesByContractName[_contractName] = _newContractAddress;
        allowedContractAddresses[_newContractAddress] = true;

        emit ContractUpdated(_contractName, _newContractAddress);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
