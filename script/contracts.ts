export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x344DEeF65b47454E2CdCe24FFCFa12f32180253B",
      [Chains.sepolia]: "0x8D6E4aa214e3eD2E895E0B6938eED63dda4c8C73",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0x49F7e71dbad648faB6A273F15e363161744a1191",
      [Chains.sepolia]: "0x8de751B764334240E54B4177300Fa8De4301deBC",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsersStore: {
    address: {
      [Chains.goerli]: "",
      [Chains.sepolia]: "",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0x90d790998f8E19A10AAb8c504c7408c1E61F040a",
      [Chains.sepolia]: "0xa86D1858D751A2f71231456fC136c4837aD76009",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0x156dA5dCA074AC3eFafa779bF24ECd0e02Fa8f18",
      [Chains.sepolia]: "0xced067Ee9Fa889156697Ea2B8fA79ced10119a3A",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0x6bA29ccEA8862BfAafC539C8504b1cD41031D86E",
      [Chains.sepolia]: "0x51132014dB4Abcd1b0EAA2ebf2914716282B51E3",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x6ae1c8968beA6F70E293daefCDD68EE7bde7e282",
      [Chains.sepolia]: "0xB219910cB49a0B1D60f73749Fa3483E1D56A694a",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0xE8Cc148Ee607BA4A880f8E106a7fBb1BAe1B2C3D",
      [Chains.sepolia]: "0x5B4d21352d0915e35874fAb36531b24c96C63400",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x3720a442E70E32C71013F07effc4033fA6249f65",
      [Chains.sepolia]: "0x66B5B57c61B606C91ffBb438b946c7b68F7aCA69",
      [Chains.gnosis]: "",
    },
  },
  LightGTCRFactory: {
    address: {
      [Chains.goerli]: "0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314",
      [Chains.sepolia]: "0x3FB8314C628E9afE7677946D3E23443Ce748Ac17",
      [Chains.gnosis]: "0x08e58Bc26CFB0d346bABD253A1799866F269805a",
    },
  },
  KlerosArbitror: {
    address: {
      [Chains.goerli]: "0x1128ed55ab2d796fa92d2f8e1f336d745354a77a",
      [Chains.sepolia]: "0x90992fb4e15ce0c59aeffb376460fda4ee19c879",
      [Chains.gnosis]: "0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002",
    },
  },
} as const;

export const isSupportedNetwork = (chainId: number): boolean => {
  return chainId in Chains;
};
