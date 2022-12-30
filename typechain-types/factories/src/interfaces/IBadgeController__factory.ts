/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IBadgeController,
  IBadgeControllerInterface,
} from "../../../src/interfaces/IBadgeController";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "badgeId",
        type: "uint256",
      },
    ],
    name: "badgeRequestValue",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "badgeId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "badgeId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "canRequestBadge",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "badgeId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "claimBadge",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "badgeId",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "createBadgeType",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "callee",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "badgeId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "requestBadge",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
] as const;

export class IBadgeController__factory {
  static readonly abi = _abi;
  static createInterface(): IBadgeControllerInterface {
    return new utils.Interface(_abi) as IBadgeControllerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IBadgeController {
    return new Contract(address, _abi, signerOrProvider) as IBadgeController;
  }
}
