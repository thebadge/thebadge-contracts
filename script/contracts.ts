export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x24a2cC73D3b33fa92B9dc299835ec3715FB033fB",
      [Chains.sepolia]: "0x276c3FDc29ef2c7CD621446448fadfcFA4acd1D6",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0x93CE70D9dfF140F33D5F7b2Cc7291D11768eCdA7",
      [Chains.sepolia]: "0xec3e7F54FD1553008f181037D8E85390d840ec02",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0x1e2D6FCF076726049F5554f848Fc332c052e0e5b",
      [Chains.sepolia]: "0x0b04F0a99c77892805308e5CFc92d84D2dDDD3d3",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0x17179b1c18AB35c78C95dE4c57eDb08b6286D60a",
      [Chains.sepolia]: "0x2A01D3c85B410eC22C90A536859D1f1cf77ED02C",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0xb3B6021e366Eb66C1ffF86e5efeB56FaBE06A265",
      [Chains.sepolia]: "0x0dcAe922A6349D4E5934b7c5Fc71bA13a22FD074",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0xda7E0959607211ede9659D0331659dEE063933F1",
      [Chains.sepolia]: "0x5914d3C5008c19cC22a39b78FA0d08b3adD4933A",
      [Chains.goerli]: "0xb3B6021e366Eb66C1ffF86e5efeB56FaBE06A265",
      [Chains.sepolia]: "0x40358153D49e4Fa1be9bF4acADB008870eE16cf1",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0x37dDEF28629aFCefF4F2F54C0eab6BaFD910F69B",
      [Chains.sepolia]: "0x9af211eEB3010e00c078E6ae9AcE1fFF5a3Fa04B",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x0c84711AaA2CebAA889cD0340C3Bf1EA721a22E6",
      [Chains.sepolia]: "0xec33015Fe4E6BdA42c40081e63d9a88fcdB0C095",
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
