export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x24a2cC73D3b33fa92B9dc299835ec3715FB033fB",
      [Chains.sepolia]: "0xE60E872Bb117AC85DBf62377557023DA9BB0e45f",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0x93CE70D9dfF140F33D5F7b2Cc7291D11768eCdA7",
      [Chains.sepolia]: "0xDE11Ada7643C4A7d07eBacA22b44178Ca01185A8",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0x1e2D6FCF076726049F5554f848Fc332c052e0e5b",
      [Chains.sepolia]: "0xCd22f18524e6eCE2Fec58574184c0c713446229e",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0x17179b1c18AB35c78C95dE4c57eDb08b6286D60a",
      [Chains.sepolia]: "0x874D3BCb8ac6fE0229F62aD2eddfe338E2500407",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0x2eB78fEC61CD7bc9780A3E45b2b2b794CB9B568D",
      [Chains.sepolia]: "0xF07ED3196B56DE833fFe82508DbD42dC427D6Ae9",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0xda7E0959607211ede9659D0331659dEE063933F1",
      [Chains.sepolia]: "0x5914d3C5008c19cC22a39b78FA0d08b3adD4933A",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0x3157c445bF3De73E66260203678Fef4FDf028104",
      [Chains.sepolia]: "0xd319B3dE32084B2763aa57612ba52D6d18470F66",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x0c84711AaA2CebAA889cD0340C3Bf1EA721a22E6",
      [Chains.sepolia]: "0x57547BaA62DD300C67d7d3Df4e9814d8E058150A",
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
