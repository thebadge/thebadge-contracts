// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { LibTheBadgeStore } from "../libraries/LibTheBadgeStore.sol";
import { LibTpBadgeModelController } from "../libraries/LibTpBadgeModelController.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { CappedMath } from "../../utils/CappedMath.sol";
import { IArbitrator } from "../../../lib/erc-792/contracts/IArbitrator.sol";
import { TpBadgeModelController } from "./TpBadgeModelController.sol";
import { TheBadgeRoles } from "../thebadge/TheBadgeRoles.sol";

contract TpBadgeModelControllerStore is OwnableUpgradeable, TheBadgeRoles {
    using CappedMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * =========================
     * Modifiers
     * =========================
     */

    // Modifier to check if the caller is one of the allowedContractAddresses contracts
    modifier onlyPermittedContract() {
        if (allowedContractAddresses[_msgSender()] == false) {
            revert LibTpBadgeModelController.ThirdPartyModelController__store_OperationNotPermitted();
        }

        _;
    }

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

    event MintThirdPartyBadge(uint256 indexed badgeId, string evidence);
    event Initialize(address indexed admin, address indexed tcrFactory);
    event ProtocolSettingsUpdated();

    /**
     * =========================
     * Types
     * =========================
     */

    /**
     * @param owner address of the creator of the model (the third party address)
     * @param administrators the list of addresses that are allowed to maintain the badgeModel apart from the owner
     */
    struct CreateBadgeModel {
        address[] administrators;
    }

    struct MintParams {
        string badgeDataUri;
    }

    struct ClaimParams {
        address recipientAddress;
    }

    /**
     * @param owner address of the creator of the model (the third party address)
     * @param badgeModelId the id of the badgeModel
     * @param tcrList The TCR List created for a particular badge model
     * @param governor An address with permission to updates parameters of the list. Use Kleros governor for full decentralization.
     * @param admin The address with permission to add/remove items directly.
     */
    struct ThirdPartyBadgeModel {
        address owner;
        uint256 badgeModelId;
        address tcrList;
        address governor;
        address admin;
    }

    /**
     * @param itemID internal TCR list ID
     * @param badgeModelId the id of the model of the badge
     * @param badgeId the id
     * @param initialized if the object was created or not
     */
    struct ThirdPartyBadge {
        bytes32 itemID;
        uint256 badgeModelId;
        uint256 badgeId;
        bool initialized;
    }

    struct ThirdPartyUser {
        address user;
        string userMetadata;
        string verificationEvidence;
        LibTpBadgeModelController.VerificationStatus verificationStatus;
        bool initialized;
    }

    /**
     * =========================
     * Store
     * =========================
     */

    CountersUpgradeable.Counter internal badgeModelIdsCounter;
    CountersUpgradeable.Counter internal badgeIdsCounter;

    TpBadgeModelController public thirdPartyModelController;
    IArbitrator public arbitrator;
    address public tcrFactory;
    address public feeCollector;
    uint256 public verifyUserProtocolFee;

    // Mapping to store contract addresses by name
    mapping(address => bool) public allowedContractAddresses;
    mapping(string => address) public allowedContractAddressesByContractName;
    mapping(uint256 => ThirdPartyBadgeModel) public thirdPartyBadgeModels;
    mapping(uint256 => ThirdPartyBadge) public thirdPartyBadges;
    mapping(address => ThirdPartyUser) public thirdPartyUsers;
    // Mapping to store the list of addresses that are allowed by the owner as co-administrators in each thirdPartyBadgeModel
    mapping(uint256 => mapping(address => bool)) public thirdPartyAdministratorsByBadgeModel;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address _feeCollector,
        address _arbitrator,
        address _tcrFactory
    ) public initializer {
        __Ownable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        feeCollector = _feeCollector;
        arbitrator = IArbitrator(_arbitrator);
        tcrFactory = _tcrFactory;
        verifyUserProtocolFee = uint256(0);
    }

    /**
     * =========================
     * Getters
     * =========================
     */
    function getUser(address userAddress) external view returns (ThirdPartyUser memory) {
        return thirdPartyUsers[userAddress];
    }

    function getBadgeModel(uint256 badgeModelId) external view returns (ThirdPartyBadgeModel memory) {
        return thirdPartyBadgeModels[badgeModelId];
    }

    function getBadge(uint256 badgeId) external view returns (ThirdPartyBadge memory) {
        return thirdPartyBadges[badgeId];
    }

    function getBadgeTcrList(uint256 badgeId) external view returns (address) {
        ThirdPartyBadge memory badge = thirdPartyBadges[badgeId];
        ThirdPartyBadgeModel memory _tpBadgeModel = thirdPartyBadgeModels[badge.badgeModelId];
        return _tpBadgeModel.tcrList;
    }

    function getCurrentBadgeModelsIdCounter() external view returns (uint256) {
        return badgeModelIdsCounter.current();
    }

    function getCurrentBadgeIdCounter() external view returns (uint256) {
        return badgeIdsCounter.current();
    }

    function isBadgeModelOwner(uint256 badgeModelId, address userAddress) external view returns (bool) {
        ThirdPartyBadgeModel memory _badgeModel = this.getBadgeModel(badgeModelId);
        return keccak256(abi.encodePacked(_badgeModel.owner)) == keccak256(abi.encodePacked(userAddress));
    }

    function isBadgeModelAdministrator(uint256 badgeModelId, address userAddress) external view returns (bool) {
        return thirdPartyAdministratorsByBadgeModel[badgeModelId][userAddress];
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
            revert LibTpBadgeModelController.ThirdPartyModelController__store_InvalidContractAddress();
        }

        // Check if the contract name already exists
        if (allowedContractAddressesByContractName[_contractName] != address(0)) {
            revert LibTpBadgeModelController.ThirdPartyModelController__store_ContractNameAlreadyExists();
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
            revert LibTpBadgeModelController.ThirdPartyModelController__store_InvalidContractName();
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
            revert LibTpBadgeModelController.ThirdPartyModelController__store_InvalidContractName();
        }

        // Update the contract address associated with the contract name
        delete allowedContractAddresses[oldContractAddress];
        allowedContractAddressesByContractName[_contractName] = _newContractAddress;
        allowedContractAddresses[_newContractAddress] = true;

        emit ContractUpdated(_contractName, _newContractAddress);
    }

    function addBadgeModel(ThirdPartyBadgeModel memory badgeModel) external onlyPermittedContract {
        thirdPartyBadgeModels[badgeModelIdsCounter.current()] = badgeModel;

        badgeModelIdsCounter.increment();
    }

    function addBadge(uint256 badgeId, ThirdPartyBadge memory badge) external onlyPermittedContract {
        thirdPartyBadges[badgeId] = badge;
        badgeIdsCounter.increment();
    }

    /**
     * @notice Creates a ThirdPartyUser's details.
     * @param userAddress The address of the user to be created.
     * @param newUser The new ThirdPartyUser struct.
     */
    function registerTpUser(address userAddress, ThirdPartyUser memory newUser) external onlyPermittedContract {
        ThirdPartyUser memory _user = thirdPartyUsers[userAddress];
        if (_user.initialized == true) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userVerificationAlreadyStarted();
        }
        thirdPartyUsers[userAddress] = newUser;
    }

    function updateUser(address userAddress, ThirdPartyUser memory updatedUser) external onlyPermittedContract {
        ThirdPartyUser memory _user = thirdPartyUsers[userAddress];
        if (bytes(_user.userMetadata).length == 0) {
            revert LibTpBadgeModelController.ThirdPartyModelController__user__userNotFound();
        }
        thirdPartyUsers[userAddress] = updatedUser;
    }

    /*
     * @notice Updates the value of the protocol: _verifyUserProtocolFee
     * @param _verifyUserProtocolFee the default fee that TheBadge protocol charges for each user verification (in bps)
     */
    function updateVerifyUserProtocolFee(uint256 _verifyUserProtocolFee) public onlyPermittedContract {
        verifyUserProtocolFee = _verifyUserProtocolFee;
    }

    /*
     * @notice Adds a new administrator to the given badgeModel
     * @param badgeModelId the id of the badgeModel
     * @param administrator the address of the adminsitrator of the badgeModel
     */
    function addAdministratorToBadgeModel(uint256 badgeModelId, address administrator) public onlyPermittedContract {
        thirdPartyAdministratorsByBadgeModel[badgeModelId][administrator] = true;
    }

    /*
     * @notice Given an array of addresses to add as administrators and a badgeModelId, adds them to the given badgeModel
     * @param badgeModelId the id of the badgeModel
     * @param administrators the array of addresses to setup as administrators of the badgeModel
     */
    function addAdministratorsToBadgeModel(uint256 badgeModelId, address[] memory administrators) public {
        for (uint256 i = 0; i < administrators.length; i++) {
            addAdministratorToBadgeModel(badgeModelId, administrators[i]);
        }
    }

    /*
     * @notice Removes a new administrator to the given badgeModel
     * @param badgeModelId the id of the badgeModel
     * @param administrator the address of the administrator of the badgeModel
     */
    function removeAdministratorFromBadgeModel(
        uint256 badgeModelId,
        address administrator
    ) public onlyPermittedContract {
        thirdPartyAdministratorsByBadgeModel[badgeModelId][administrator] = false;
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
