// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { LibTheBadgeUsers } from "../libraries/LibTheBadgeUsers.sol";
import { LibTheBadgeStore } from "../libraries/LibTheBadgeStore.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TheBadgeUsersStore is TheBadgeRoles, OwnableUpgradeable {
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

    uint256 public registerUserProtocolFee;

    /**
     * =========================
     * Types
     * =========================
     */

    /**
     * @param metadata information related with the user.
     * @param isCompany true if the user is a company, otherwise is false (default value)
     * @param isCreator true if the user has created at least one badge model
     * @param suspended If true, the user is not allowed to do any actions and if it's a creator, their badges are not mintable anymore.
     * @param initialized When the struct is created its true, if the struct was never initialized, its false, used in validations
     */
    struct User {
        string metadata;
        bool isCompany;
        bool isCreator;
        bool suspended;
        bool initialized;
    }

    // Mapping to store contract addresses by name
    mapping(address => bool) public allowedContractAddresses;
    mapping(string => address) public allowedContractAddressesByContractName;
    mapping(address => User) public registeredUsers;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) public initializer {
        __Ownable_init(admin);
        registerUserProtocolFee = uint256(0);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * =========================
     * Getters
     * =========================
     */
    function getUser(address userAddress) external view returns (User memory) {
        return registeredUsers[userAddress];
    }

    /**
     * =========================
     * Setters
     * =========================
     */
    function createUser(address userAddress, User calldata newUser) external onlyPermittedContract {
        User storage _user = registeredUsers[userAddress];
        if (_user.initialized == true) {
            revert LibTheBadgeUsers.TheBadge__registerUser_alreadyRegistered();
        }
        registeredUsers[userAddress] = newUser;
    }

    function updateUser(address userAddress, User calldata updatedUser) external onlyPermittedContract {
        User storage _user = registeredUsers[userAddress];
        if (_user.initialized == false) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }
        registeredUsers[userAddress] = updatedUser;
    }

    /*
     * @notice Updates the value of the protocol: _registerCreatorValue
     * @param _registerCreatorValue the default fee that TheBadge protocol charges for each user registration (in bps)
     */
    function updateRegisterCreatorProtocolFee(uint256 _registerCreatorValue) public onlyPermittedContract {
        registerUserProtocolFee = _registerCreatorValue;
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
    uint256[50] private __gap;

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
