export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x86F127fef233C799f2aA130cCc919045f954957d",
      [Chains.sepolia]: "0x83701fe7a462bD714A9006a9FF604367C24613E3",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0xffAA3c8735502799b91Fff9Df5cE4fbE9411b3Da",
      [Chains.sepolia]: "0x79Ffb85704b223B39d924233A14c849F5A3dC2e2",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0x196EF38Eca64a6FEa6E6Fc8AdF85Ac1BE44f4804",
      [Chains.sepolia]: "0x5E7c648EE852241f145e1d480932C091979883D1",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0x20933724e3C2F177d8Cfe4b1CEEF829A17aD883B",
      [Chains.sepolia]: "0x5df8183d0B77Bea3B72391eB0c4c873d2fdDC6f2",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0xb3E297419486C8105a6bF5BA679A01C2567a6336",
      [Chains.sepolia]: "0x93549ecf683cc80C4aE73e2dbf11cb0FA51bc303",
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
